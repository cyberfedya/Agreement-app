using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Fetches a deal's generated agreement by id - the cross-device
/// counterpart to <see cref="GenerateFromDealUseCase"/>. This is what lets
/// a second device (the party that scanned the QR code) retrieve the same
/// document the creator generated, instead of relying on any local state.
/// </summary>
public sealed class GetDealAgreementUseCase(IDealRepository dealRepository)
{
    public async Task<GenerateAgreementResponse?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal?.GeneratedHtml is null)
            return null;

        return new GenerateAgreementResponse(deal.Id.ToString(), deal.GeneratedHtml, deal.UpdatedAt, deal.SecondPartyName);
    }
}
