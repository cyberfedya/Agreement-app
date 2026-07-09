using System.Text.Json;

namespace EasyAgree.Application.Documents;

public static class ExtractedDocumentFieldsSerializer
{
    public static Dictionary<string, ExtractedFieldValue> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, ExtractedFieldValue>>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlyDictionary<string, ExtractedFieldValue> fields) =>
        JsonSerializer.Serialize(fields);
}
