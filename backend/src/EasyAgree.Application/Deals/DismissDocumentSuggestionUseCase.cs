using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Records "Continue without document" for one document type on a deal,
/// so <see cref="Interview.DocumentSuggestionEngine"/> never suggests it
/// again for the rest of this interview.
/// </summary>
public sealed class DismissDocumentSuggestionUseCase(IDealRepository dealRepository)
{
    public async Task<bool> ExecuteAsync(Guid dealId, string documentType, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return false;

        var dismissed = DealDismissedDocumentSuggestionsSerializer.Deserialize(deal.DismissedDocumentSuggestionsJson);
        dismissed.Add(documentType);

        deal.DismissedDocumentSuggestionsJson = DealDismissedDocumentSuggestionsSerializer.Serialize(dismissed);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
        return true;
    }
}
