using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

public sealed record DocumentFieldHint(
    string Key,
    string Value,
    double Confidence,
    string Source);

public sealed class DocumentFieldHintCollection
{
    private const double MinimumPromptConfidence = 0.5;

    public DocumentFieldHintCollection(IReadOnlyList<DocumentFieldHint> fields)
    {
        Fields = fields;
    }

    public IReadOnlyList<DocumentFieldHint> Fields { get; }

    public static DocumentFieldHintCollection FromDocuments(IEnumerable<UploadedDocument> documents)
    {
        var merged = new Dictionary<string, DocumentFieldHint>(StringComparer.OrdinalIgnoreCase);

        foreach (var document in documents.Where(d => d.Status == DocumentProcessingStatus.Processed))
        {
            foreach (var (key, field) in ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson))
            {
                if (field.Confidence < MinimumPromptConfidence || string.IsNullOrWhiteSpace(field.Value))
                    continue;

                if (!merged.TryGetValue(key, out var existing) || field.Confidence > existing.Confidence)
                    merged[key] = new DocumentFieldHint(key, field.Value, field.Confidence, "document");
            }

            // Normalized values are a separate layer over immutable raw
            // extraction. User corrections win for the same document key;
            // raw OCR/Vision data remains untouched and can be remapped.
            foreach (var (key, field) in NormalizedDocumentFieldsSerializer.Deserialize(document.NormalizedFieldsJson))
            {
                if (string.IsNullOrWhiteSpace(field.Value))
                    continue;

                merged[key] = new DocumentFieldHint(key, field.Value, field.Confidence, field.Source);
            }
        }

        return new DocumentFieldHintCollection(merged.Values.OrderBy(f => f.Key).ToList());
    }

    public static DocumentFieldHintCollection FromProfile(UserProfile? profile)
    {
        if (profile is null)
            return Empty;

        var fields = new List<DocumentFieldHint>();
        Add(fields, "profile_full_name", profile.FullName);
        Add(fields, "profile_passport_number", profile.PassportNumber);
        Add(fields, "profile_birth_date", profile.BirthDate);
        Add(fields, "profile_address", profile.Address);
        return new DocumentFieldHintCollection(fields);
    }

    public static DocumentFieldHintCollection Combine(params DocumentFieldHintCollection[] collections) =>
        new(collections.SelectMany(c => c.Fields).ToList());

    public static DocumentFieldHintCollection Empty { get; } = new([]);

    public string? ToPromptContext()
    {
        if (Fields.Count == 0)
            return null;

        return string.Join('\n', Fields.Select(f => $"{f.Key} = {f.Value} (confidence {f.Confidence:0.00}, source {f.Source})"));
    }

    private static void Add(List<DocumentFieldHint> fields, string key, string value)
    {
        if (!string.IsNullOrWhiteSpace(value))
            fields.Add(new DocumentFieldHint(key, value, 1.0, "account_profile"));
    }
}
