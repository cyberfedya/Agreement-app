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

    public void ApplyHighConfidenceAnswers(Dictionary<int, string> answers, double threshold = 0.75)
    {
        foreach (var (fieldId, field) in Fields)
        {
            if (!answers.ContainsKey(fieldId) && field.Confidence >= threshold && !string.IsNullOrWhiteSpace(field.Value))
                answers[fieldId] = field.Value;
        }
    }

    public void RemoveOwnedAnswers(Dictionary<int, string> answers)
    {
        foreach (var (fieldId, field) in Fields)
        {
            if (field.Source is not ("document" or "account_profile"))
                continue;

            if (answers.TryGetValue(fieldId, out var current) && current == field.Value)
                answers.Remove(fieldId);
        }
    }

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
