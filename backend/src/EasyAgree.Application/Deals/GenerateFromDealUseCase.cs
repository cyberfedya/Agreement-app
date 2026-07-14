using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Finalizes a deal into a first draft. The interview deliberately asks
/// only about the agreement's object and terms, so the full required-field
/// set is assembled here from three sources, in priority order:
///   1. answers persisted on the deal (interview answers + AI-extracted
///      values from the original request) and answers sent with this call,
///   2. the creator's profile (their own party details — never asked),
///   3. the second party's profile, once they've accepted the invite via
///      <see cref="AcceptDealInviteUseCase"/> (null until then),
///   4. a visible blank placeholder for whatever's still missing (notarial
///      metadata, or a party whose profile isn't linked/filled in yet).
///
/// Profile-resolved values and placeholders are deliberately never written
/// back into <c>Deal.AnswersJson</c> - only genuine answers are - so this
/// use case can be called again later (e.g. right after the second party
/// accepts) and pick up newly-available profile data instead of being
/// stuck with whatever placeholder got persisted the first time.
/// </summary>
public sealed class GenerateFromDealUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUserProfileRepository profileRepository,
    IUploadedDocumentRepository documentRepository,
    PartyProfileResolver partyProfileResolver,
    GenerateAgreementUseCase generateAgreement)
{
    private const string PendingPlaceholder = "____________";

    public async Task<GenerateFromDealResult> ExecuteAsync(
        Guid dealId, IReadOnlyDictionary<int, string> answers, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return GenerateFromDealResult.NotFound();

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return GenerateFromDealResult.NotFound();

        if (DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson).Any(response =>
                response.Type is DealPartyResponseTypes.ProposedChange or DealPartyResponseTypes.Clarification) ||
            deal.InviteStatus is InviteStatus.ChangeRequested or InviteStatus.ClarificationRequested)
        {
            return GenerateFromDealResult.LegalReviewRequired();
        }

        var merged = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        foreach (var (fieldId, value) in answers)
        {
            if (!string.IsNullOrWhiteSpace(value))
                merged[fieldId] = value;
        }

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        if (DocumentConflictEngine.Detect(documents).Any(conflict => conflict.Severity == "HIGH"))
            return GenerateFromDealResult.LegalReviewRequired();
        var documentHints = DocumentFieldHintCollection.FromDocuments(documents);
        DocumentFieldMapper.ApplyMatches(template.Fields, labels, documentHints, merged);
        var creatorProfile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);
        var secondPartyProfile = deal.SecondPartyProfileId is null
            ? null
            : await profileRepository.GetAsync(deal.SecondPartyProfileId, cancellationToken);
        var roleResolution = await partyProfileResolver.ResolveRoleAsync(
            labels, deal.RequestText, deal.FirstPartyRole, deal.ExpectedSecondPartyRole, cancellationToken);
        var forRender = new Dictionary<int, string>(merged);
        foreach (var field in template.Fields)
        {
            if (field.Mode != AgreementFieldMode.Required || forRender.ContainsKey(field.FieldId))
                continue;

            var label = labels.GetValueOrDefault(field.FieldId, string.Empty);
            var resolved =
                (creatorProfile is null ? null : PartyProfileResolver.ResolveFromProfile(label, creatorProfile, roleResolution.CreatorKeywords))
                ?? (secondPartyProfile is null ? null : PartyProfileResolver.ResolveFromProfile(label, secondPartyProfile, roleResolution.SecondPartyKeywords));
            forRender[field.FieldId] = string.IsNullOrWhiteSpace(resolved) ? PendingPlaceholder : resolved;
        }

        var result = await generateAgreement.ExecuteAsync(deal.TemplateKey, forRender, cancellationToken);
        if (result.IsNotFound)
            return GenerateFromDealResult.NotFound();
        if (result.MissingFieldIds is { Count: > 0 })
            return GenerateFromDealResult.MissingFields(result.MissingFieldIds);
        deal.AnswersJson = DealAnswersSerializer.Serialize(merged);
        deal.GeneratedHtml = result.Html;
        if (deal.Status != DealStatus.FullySigned)
            deal.Status = DealStatus.Completed;
        deal.FirstPartyRole = roleResolution.CreatorRoleCode;
        deal.ExpectedSecondPartyRole = roleResolution.SecondPartyRoleCode;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return GenerateFromDealResult.Success(result.Html!);
    }
}