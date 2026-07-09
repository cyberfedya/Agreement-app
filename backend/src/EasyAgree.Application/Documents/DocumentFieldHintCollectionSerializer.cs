using System.Text.Json;

namespace EasyAgree.Application.Documents;

public static class DocumentFieldHintCollectionSerializer
{
    public static DocumentFieldHintCollection Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return DocumentFieldHintCollection.Empty;

        try
        {
            if (JsonSerializer.Deserialize<List<DocumentFieldHint>>(json) is { } fields)
                return new DocumentFieldHintCollection(fields);
        }
        catch (JsonException)
        {
        }

        return DocumentFieldHintCollection.Empty;
    }

    public static string Serialize(DocumentFieldHintCollection collection) =>
        JsonSerializer.Serialize(collection.Fields);
}
