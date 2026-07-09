using System.Text.Json;

namespace EasyAgree.Application.Deals;

/// <summary>
/// (De)serializes <c>Deal.AnswersJson</c> (<c>{"3":"answer",...}</c>) —
/// the single place both the interview planner and generation read/write
/// the persisted answer set, so they can never drift apart.
/// </summary>
public static class DealAnswersSerializer
{
    public static Dictionary<int, string> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json)?
                .ToDictionary(kv => int.Parse(kv.Key), kv => kv.Value) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlyDictionary<int, string> answers) =>
        JsonSerializer.Serialize(answers.ToDictionary(kv => kv.Key.ToString(), kv => kv.Value));
}
