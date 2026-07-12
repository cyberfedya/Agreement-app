using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public enum DeclineInviteOutcome
{
    Declined,
    DealNotFound,
    AlreadyAccepted,
}

public sealed record DeclineInviteResult(DeclineInviteOutcome Outcome);

public sealed class DeclineDealInviteUseCase(IDealRepository dealRepository)
{
    public async Task<DeclineInviteResult> ExecuteAsync(
        Guid dealId,
        string? reason,
        string? profileId,
        CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return new DeclineInviteResult(DeclineInviteOutcome.DealNotFound);

        if (deal.InviteStatus == InviteStatus.Accepted)
            return new DeclineInviteResult(DeclineInviteOutcome.AlreadyAccepted);

        var responses = DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson);
        responses.Add(new DealPartyResponse(
            DealPartyResponseTypes.Decline,
            null,
            null,
            string.IsNullOrWhiteSpace(reason) ? null : reason.Trim(),
            string.IsNullOrWhiteSpace(profileId) ? deal.SecondPartyProfileId : profileId.Trim(),
            DateTime.UtcNow));

        deal.InviteStatus = InviteStatus.Declined;
        deal.PartyResponsesJson = DealPartyResponseSerializer.Serialize(responses);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return new DeclineInviteResult(DeclineInviteOutcome.Declined);
    }
}
