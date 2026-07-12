using System.Text.Json;

namespace EasyAgree.Application.Documents;

public static class NormalizedDocumentFieldsSerializer
{
    public static Dictionary<string, NormalizedDocumentFieldValue> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, NormalizedDocumentFieldValue>>(json)
                ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IReadOnlyDictionary<string, NormalizedDocumentFieldValue> fields) =>
        JsonSerializer.Serialize(fields);
}
