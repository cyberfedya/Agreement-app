using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Records the creator's (first party's) signature. Mirrors
/// <see cref="SignDealSecondPartyUseCase"/> exactly, but writes to the
/// first-party fields only - neither use case ever touches the other
/// party's timestamp, so either party may sign first and the deal only
/// reaches <see cref="DealStatus.FullySigned"/> once both are set.
/// </summary>
public sealed class SignDealFirstPartyUseCase(IDealRepository dealRepository)
{
    public async Task<bool> ExecuteAsync(Guid dealId, string fullName, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal?.GeneratedHtml is null)
            return false;

        deal.FirstPartyName = fullName;
        deal.FirstPartySignedAt ??= DateTime.UtcNow;
        if (deal.SecondPartySignedAt is not null)
            deal.Status = DealStatus.FullySigned;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
        return true;
    }
}
