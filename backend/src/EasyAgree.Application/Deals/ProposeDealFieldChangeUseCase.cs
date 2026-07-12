using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public enum ProposeFieldChangeOutcome
{
    Recorded,
    DealNotFound,
    InvalidField,
}

public sealed record ProposeFieldChangeResult(ProposeFieldChangeOutcome Outcome);

public sealed class ProposeDealFieldChangeUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository)
{
    public async Task<ProposeFieldChangeResult> ExecuteAsync(
        Guid dealId,
        int fieldId,
        string proposedValue,
        string? reason,
        string? profileId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(proposedValue))
            return new ProposeFieldChangeResult(ProposeFieldChangeOutcome.InvalidField);

        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return new ProposeFieldChangeResult(ProposeFieldChangeOutcome.DealNotFound);

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null || template.Fields.All(f => f.FieldId != fieldId))
            return new ProposeFieldChangeResult(ProposeFieldChangeOutcome.InvalidField);

        var responses = DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson)
            .Where(r => r.Type != DealPartyResponseTypes.ProposedChange || r.FieldId != fieldId)
            .ToList();
        responses.Add(new DealPartyResponse(
            DealPartyResponseTypes.ProposedChange,
            fieldId,
            proposedValue.Trim(),
            string.IsNullOrWhiteSpace(reason) ? null : reason.Trim(),
            string.IsNullOrWhiteSpace(profileId) ? deal.SecondPartyProfileId : profileId.Trim(),
            DateTime.UtcNow));

        deal.InviteStatus = InviteStatus.ChangeRequested;
        deal.PartyResponsesJson = DealPartyResponseSerializer.Serialize(responses);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return new ProposeFieldChangeResult(ProposeFieldChangeOutcome.Recorded);
    }
}
