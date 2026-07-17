using System.Text.Json;

namespace EasyAgree.Application.Deals;

/// <summary>
/// (De)serializes <c>Deal.DeferredFieldIdsJson</c> — a plain JSON array of
/// field ids the user said they don't know/can't check right now.
/// </summary>
public static class DealDeferredFieldIdsSerializer
{
    public static HashSet<int> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<HashSet<int>>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlySet<int> deferred) => JsonSerializer.Serialize(deferred);
}
