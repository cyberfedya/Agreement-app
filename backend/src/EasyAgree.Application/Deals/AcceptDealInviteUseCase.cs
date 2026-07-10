using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public enum AcceptInviteOutcome
{
    Accepted,
    DealNotFound,
    AlreadyResponded,
    OwnInvite,
    Expired,
}

public sealed record AcceptInviteResult(AcceptInviteOutcome Outcome);

/// <summary>
/// Links the second party's own profile to the deal - nothing more. No
/// HTML, no regeneration; that happens separately (the client re-calls
/// /generate once this succeeds, which is what lets the newly-linked
/// profile actually show up in the document).
/// </summary>
public sealed class AcceptDealInviteUseCase(IDealRepository dealRepository)
{
    public async Task<AcceptInviteResult> ExecuteAsync(
        Guid dealId, string profileId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return new AcceptInviteResult(AcceptInviteOutcome.DealNotFound);

        if (deal.InviteStatus is InviteStatus.Accepted or InviteStatus.Declined)
            return new AcceptInviteResult(AcceptInviteOutcome.AlreadyResponded);

        if (deal.InviteExpiresAt is { } expiresAt && expiresAt <= DateTime.UtcNow)
            return new AcceptInviteResult(AcceptInviteOutcome.Expired);

        if (!string.IsNullOrWhiteSpace(deal.ProfileId) && deal.ProfileId == profileId)
            return new AcceptInviteResult(AcceptInviteOutcome.OwnInvite);

        deal.SecondPartyProfileId = profileId;
        deal.InviteStatus = InviteStatus.Accepted;
        deal.AcceptedAt = DateTime.UtcNow;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return new AcceptInviteResult(AcceptInviteOutcome.Accepted);
    }
}
