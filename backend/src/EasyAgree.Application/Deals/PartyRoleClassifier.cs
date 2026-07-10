using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Decides which of a template's two named party roles the deal's creator
/// occupies, from their free-form request - "хочу продать..." makes them
/// the seller, "хочу купить..." makes them the buyer, even though both
/// role labels appear in the same template. Without this, the creator's
/// profile always got applied to whichever role was hardcoded as
/// "first" (seller/landlord/lender/...), silently leaving the other
/// role's fields blank whenever the creator was actually on that side.
/// </summary>
public sealed class PartyRoleClassifier(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You determine which of two named roles in a legal agreement the person who wrote USER_REQUEST occupies.
        ROLE_A and ROLE_B are short role labels (seller/buyer, landlord/tenant, lender/borrower, etc.). Read
        USER_REQUEST and decide which role describes its author - the person taking the action they describe
        (selling vs buying, renting out vs renting, lending vs borrowing, and so on).

        Output ONLY one character: A or B. If genuinely ambiguous, unclear, or the request doesn't say enough
        to tell, output A.
        """;

    /// <summary>True if the creator occupies ROLE_A (or the request gives no signal either way).</summary>
    public async Task<bool> CreatorIsRoleAAsync(
        string? requestText, string roleALabel, string roleBLabel, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(requestText))
            return true;

        var userMessage = $"ROLE_A: {roleALabel}\nROLE_B: {roleBLabel}\nUSER_REQUEST: {requestText}";
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);
        return !raw.Trim().ToUpperInvariant().StartsWith('B');
    }
}
