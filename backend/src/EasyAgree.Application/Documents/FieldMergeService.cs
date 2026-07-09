using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

public sealed class FieldMergeService : IFieldMergeService
{
    private const double MinimumUsableConfidence = 0.5;

    public string? BuildDocumentContext(IEnumerable<UploadedDocument> documents)
    {
        var merged = new Dictionary<string, ExtractedFieldValue>();

        foreach (var document in documents.Where(d => d.Status == DocumentProcessingStatus.Processed))
        {
            foreach (var (key, field) in ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson))
            {
                if (field.Confidence < MinimumUsableConfidence)
                    continue;

                // Highest confidence wins when multiple documents state the same field.
                if (!merged.TryGetValue(key, out var existing) || field.Confidence > existing.Confidence)
                    merged[key] = field;
            }
        }

        if (merged.Count == 0)
            return null;

        return string.Join('\n', merged.Select(kv => $"{kv.Key} = {kv.Value.Value} (confidence {kv.Value.Confidence:0.00})"));
    }
}
