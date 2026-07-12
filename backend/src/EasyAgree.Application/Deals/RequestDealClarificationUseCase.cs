using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public enum RequestClarificationOutcome
{
    Recorded,
    DealNotFound,
    EmptyMessage,
}

public sealed record RequestClarificationResult(RequestClarificationOutcome Outcome);

public sealed class RequestDealClarificationUseCase(IDealRepository dealRepository)
{
    public async Task<RequestClarificationResult> ExecuteAsync(
        Guid dealId,
        string message,
        string? profileId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(message))
            return new RequestClarificationResult(RequestClarificationOutcome.EmptyMessage);

        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return new RequestClarificationResult(RequestClarificationOutcome.DealNotFound);

        var responses = DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson);
        responses.Add(new DealPartyResponse(
            DealPartyResponseTypes.Clarification,
            null,
            null,
            message.Trim(),
            string.IsNullOrWhiteSpace(profileId) ? deal.SecondPartyProfileId : profileId.Trim(),
            DateTime.UtcNow));

        deal.InviteStatus = InviteStatus.ClarificationRequested;
        deal.PartyResponsesJson = DealPartyResponseSerializer.Serialize(responses);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return new RequestClarificationResult(RequestClarificationOutcome.Recorded);
    }
}
