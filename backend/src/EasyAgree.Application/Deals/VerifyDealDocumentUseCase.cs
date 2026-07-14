using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Runs <see cref="DocumentVerificationEngine"/> against a deal's current
/// answers and whatever's been uploaded for it, then persists the silent
/// auto-fills immediately (so a regenerate right after this call already
/// has them) while leaving genuine conflicts for the caller to resolve
/// through the existing answer-correction path - this use case itself
/// never writes a conflicting value, only agreement.
/// </summary>
public sealed class VerifyDealDocumentUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<DocumentVerificationOutcome?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var hints = DocumentFieldHintCollection.FromDocuments(documents);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);

        var outcome = DocumentVerificationEngine.Evaluate(template.Fields, labels, answers, hints);

        if (outcome.AutoFilled.Count > 0)
        {
            foreach (var (fieldId, value) in outcome.AutoFilled)
                answers[fieldId] = value;

            deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
            deal.UpdatedAt = DateTime.UtcNow;
            await dealRepository.UpdateAsync(deal, cancellationToken);
        }

        return outcome;
    }
}
