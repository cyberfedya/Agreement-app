using System.Text.Json;

namespace EasyAgree.Application.Deals;

/// <summary>
/// (De)serializes <c>Deal.DismissedDocumentSuggestionsJson</c> — a plain
/// JSON array of <c>DocumentType.ToString()</c> values the user chose
/// "Continue without document" for.
/// </summary>
public static class DealDismissedDocumentSuggestionsSerializer
{
    public static HashSet<string> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<HashSet<string>>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlySet<string> dismissed) => JsonSerializer.Serialize(dismissed);
}
