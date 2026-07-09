using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Deals.Interview;

public sealed record InterviewPreviewResult(int TotalAskableFields, int EstimatedRemainingQuestions);

/// <summary>
/// A cheap, honest preview of "how many questions are left" right after
/// document upload - reuses the real extraction machinery (one
/// <see cref="QuestionGenerator"/> call against every still-askable field
/// at once) rather than a made-up estimate, so the number shown actually
/// matches what the interview is about to do. Doesn't touch the answer
/// set - purely a read.
/// </summary>
public sealed class GetInterviewPreviewUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository)
{
    public async Task<InterviewPreviewResult?> ExecuteAsync(
        Guid dealId, string language, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);

        var classified = FieldEligibilityEngine.Classify(template.Fields, labels);
        var askable = classified
            .Where(f => f.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .Where(f => !answers.ContainsKey(f.FieldId))
            .ToList();

        if (askable.Count == 0)
            return new InterviewPreviewResult(0, 0);

        return new InterviewPreviewResult(askable.Count, askable.Count);
    }
}
