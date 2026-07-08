using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>Finalizes a deal: generates the document from its template and answers, then marks it completed.</summary>
public sealed class GenerateFromDealUseCase(IDealRepository dealRepository, GenerateAgreementUseCase generateAgreement)
{
    public async Task<GenerateFromDealResult> ExecuteAsync(
        Guid dealId, IReadOnlyDictionary<int, string> answers, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return GenerateFromDealResult.NotFound();

        var result = await generateAgreement.ExecuteAsync(deal.TemplateKey, answers, cancellationToken);
        if (result.IsNotFound)
            return GenerateFromDealResult.NotFound();
        if (result.MissingFieldIds is { Count: > 0 })
            return GenerateFromDealResult.MissingFields(result.MissingFieldIds);

        deal.GeneratedHtml = result.Html;
        deal.Status = DealStatus.Completed;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return GenerateFromDealResult.Success(result.Html!);
    }
}
