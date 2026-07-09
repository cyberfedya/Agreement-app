using System.Text.Json;

namespace EasyAgree.Application.Documents;

public static class MergedFieldCollectionSerializer
{
    public static MergedFieldCollection Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return new MergedFieldCollection(new Dictionary<int, MergedFieldValue>());

        try
        {
            var fields = JsonSerializer.Deserialize<Dictionary<string, MergedFieldValue>>(json)?
                .ToDictionary(kv => int.Parse(kv.Key), kv => kv.Value) ?? [];
            return new MergedFieldCollection(fields);
        }
        catch (JsonException)
        {
            return new MergedFieldCollection(new Dictionary<int, MergedFieldValue>());
        }
    }

    public static string Serialize(MergedFieldCollection collection) =>
        JsonSerializer.Serialize(collection.Fields.ToDictionary(kv => kv.Key.ToString(), kv => kv.Value));
}
