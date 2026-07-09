using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Records the second party's signature after they complete identification
/// on their own device (post QR-scan). Persisted on the <see cref="EasyAgree.Domain.Entities.Deal"/>
/// itself - there's no separate signatures table yet, one signer is all
/// the current agreement flow needs.
/// </summary>
public sealed class SignDealSecondPartyUseCase(IDealRepository dealRepository)
{
    public async Task<bool> ExecuteAsync(Guid dealId, string fullName, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal?.GeneratedHtml is null)
            return false;

        deal.SecondPartyName = fullName;
        deal.SecondPartySignedAt = DateTime.UtcNow;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
        return true;
    }
}
