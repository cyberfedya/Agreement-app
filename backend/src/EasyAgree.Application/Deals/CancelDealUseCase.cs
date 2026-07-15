using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public enum CancelDealOutcome
{
    Cancelled,
    DealNotFound,
    AlreadySigned,
}

public sealed record CancelDealResult(CancelDealOutcome Outcome);

/// <summary>Lets the creator cancel a deal that hasn't been fully signed yet (from Deal History).</summary>
public sealed class CancelDealUseCase(IDealRepository dealRepository)
{
    public async Task<CancelDealResult> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return new CancelDealResult(CancelDealOutcome.DealNotFound);

        if (deal.Status == DealStatus.FullySigned)
            return new CancelDealResult(CancelDealOutcome.AlreadySigned);

        deal.Status = DealStatus.Cancelled;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return new CancelDealResult(CancelDealOutcome.Cancelled);
    }
}
