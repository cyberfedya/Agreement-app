using System.Text.Json;

namespace EasyAgree.Application.Deals;

/// <summary>
/// (De)serializes <c>Deal.AskedQuestionsJson</c> — the exact wording last
/// used per group-of-fields signature, so the interview planner can
/// recognize a repeat ask across HTTP turns. Mirrors
/// <see cref="DealAnswersSerializer"/>, but keyed by group signature
/// string (e.g. <c>"18,19"</c>) rather than a single field id.
/// </summary>
public static class DealAskedQuestionsSerializer
{
    public static Dictionary<string, string> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlyDictionary<string, string> askedQuestions) =>
        JsonSerializer.Serialize(askedQuestions);
}
