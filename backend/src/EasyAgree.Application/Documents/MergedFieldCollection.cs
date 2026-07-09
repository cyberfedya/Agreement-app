namespace EasyAgree.Application.Documents;

public sealed record MergedFieldValue(
    int FieldId,
    string Value,
    double Confidence,
    string Source);

public sealed class MergedFieldCollection
{
    public MergedFieldCollection(IReadOnlyDictionary<int, MergedFieldValue> fields)
    {
        Fields = fields;
    }

    public IReadOnlyDictionary<int, MergedFieldValue> Fields { get; }

    public bool HasHighConfidenceValue(int fieldId, double threshold = 0.75) =>
        Fields.TryGetValue(fieldId, out var value) &&
        value.Confidence >= threshold &&
        !string.IsNullOrWhiteSpace(value.Value);

    public string? ToPromptContext(double threshold = 0.75)
    {
        var knownFields = Fields.Values
            .Where(f => f.Confidence >= threshold)
            .OrderBy(f => f.FieldId)
            .ToList();

        if (knownFields.Count == 0)
            return null;

        return string.Join('\n', knownFields
            .Select(f => $"{f.FieldId} = {f.Value} (confidence {f.Confidence:0.00}, source {f.Source})"));
    }
}
