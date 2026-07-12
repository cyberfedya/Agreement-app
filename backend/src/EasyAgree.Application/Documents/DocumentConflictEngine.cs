using System.Text.RegularExpressions;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

/// <summary>Pure cross-document consistency check. Only stable identifiers
/// and material agreement values are compared; arbitrary OCR keys are not
/// treated as conflicts to avoid noisy false positives.</summary>
public static partial class DocumentConflictEngine
{
    private static readonly IReadOnlyDictionary<string, (string Type, string Severity)> SensitiveFields =
        new Dictionary<string, (string, string)>(StringComparer.OrdinalIgnoreCase)
        {
            ["vin"] = ("VIN_MISMATCH", "HIGH"),
            ["cadastre_number"] = ("CADASTRE_MISMATCH", "HIGH"),
            ["passport_number"] = ("PASSPORT_MISMATCH", "HIGH"),
            ["plate_number"] = ("PLATE_MISMATCH", "MEDIUM"),
            ["price"] = ("PRICE_MISMATCH", "MEDIUM"),
            ["normalized_amount"] = ("PRICE_MISMATCH", "MEDIUM"),
            ["currency"] = ("CURRENCY_MISMATCH", "MEDIUM"),
            ["address"] = ("ADDRESS_MISMATCH", "MEDIUM"),
            ["property_address"] = ("ADDRESS_MISMATCH", "MEDIUM"),
            ["full_name"] = ("OWNER_MISMATCH", "HIGH"),
        };

    public static IReadOnlyList<DocumentConflict> Detect(IEnumerable<UploadedDocument> documents)
    {
        var facts = new Dictionary<string, List<DocumentConflictValue>>(StringComparer.OrdinalIgnoreCase);
        foreach (var document in documents.Where(d => d.Status == DocumentProcessingStatus.Processed))
        {
            var effective = ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson)
                .ToDictionary(pair => pair.Key, pair => new DocumentConflictValue(document.Id, document.FileName, pair.Value.Value, pair.Value.Confidence, "document"), StringComparer.OrdinalIgnoreCase);
            foreach (var (key, value) in NormalizedDocumentFieldsSerializer.Deserialize(document.NormalizedFieldsJson))
                effective[key] = new DocumentConflictValue(document.Id, document.FileName, value.Value, value.Confidence, value.Source);

            foreach (var (key, value) in effective)
            {
                if (!SensitiveFields.ContainsKey(key) || value.Confidence < 0.5 || string.IsNullOrWhiteSpace(value.Value))
                    continue;
                if (!facts.TryGetValue(key, out var values)) facts[key] = values = [];
                values.Add(value);
            }
        }

        return facts
            .Where(pair => NormalizedDistinctCount(pair.Value) > 1)
            .OrderBy(pair => pair.Key, StringComparer.Ordinal)
            .Select(pair => Create(pair.Key, pair.Value))
            .ToList();
    }

    private static DocumentConflict Create(string field, IReadOnlyList<DocumentConflictValue> values)
    {
        var (type, severity) = SensitiveFields[field];
        return new DocumentConflict(
            type,
            field,
            severity,
            $"Independent documents contain different {field} values.",
            $"Verify {field} and explicitly confirm the correct value before generation.",
            values);
    }

    private static int NormalizedDistinctCount(IEnumerable<DocumentConflictValue> values) =>
        values.Select(value => Normalize(value.Value)).Distinct(StringComparer.Ordinal).Count();

    private static string Normalize(string value) => NonAlphaNumeric().Replace(value, string.Empty).ToUpperInvariant();

    [GeneratedRegex("[^A-Za-z0-9]")]
    private static partial Regex NonAlphaNumeric();
}
