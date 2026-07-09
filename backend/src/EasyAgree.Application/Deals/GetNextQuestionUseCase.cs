using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Thin adapter between the deal/template persistence layer and the
/// <see cref="ConversationManager"/>: loads state, delegates the actual
/// intent classification + planning, then persists whatever ended up
/// written to the answer set before returning.
/// </summary>
public sealed class GetNextQuestionUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    ConversationManager conversationManager)
{
    public async Task<NextQuestionResult> ExecuteAsync(
        Guid dealId,
        int? answeredFieldId,
        string? answerText,
        string? currentQuestionText,
        string language,
        CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return NextQuestionResult.NotFound();

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return NextQuestionResult.NotFound();

        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var (title, _) = TranslationResolver.Resolve(template.Translations, language);

        var result = await conversationManager.ExecuteAsync(
            title, language, deal.RequestText, answeredFieldId, answerText, currentQuestionText,
            template.Fields, labels, answers, cancellationToken);

        await SaveAnswersAsync(deal, answers, cancellationToken);

        return result.IsReady
            ? NextQuestionResult.ReadyToGenerate(result.Question!)
            : NextQuestionResult.NeedMoreInfo(result.FieldId!.Value, result.Question!);
    }

    private async Task SaveAnswersAsync(Deal deal, Dictionary<int, string> answers, CancellationToken cancellationToken)
    {
        deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }
}
