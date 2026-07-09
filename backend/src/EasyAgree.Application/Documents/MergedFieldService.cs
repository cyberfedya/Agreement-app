using System.Text.Json;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

public sealed class MergedFieldService(IAiChatClient aiChatClient) : IFieldMergeService
{
    private const double MinimumUsableConfidence = 0.5;

    private const string SystemPrompt = """
        You map already-extracted structured intake data to agreement template field ids.

        The input contains:
        - FIELD_CATALOG: template field ids with labels.
        - EXISTING_ANSWERS: conversation memory already keyed by field id.
        - DOCUMENT_FIELDS: structured values extracted from uploaded documents. This is not raw OCR.
        - ACCOUNT_PROFILE: profile values.

        Return only facts that clearly answer a field in FIELD_CATALOG. Never guess.
        Use the original confidence for document values. Use confidence 1.0 for existing answers and profile values.
        If multiple values answer the same field, keep the highest-confidence value.
        Do not include a field when the value is unrelated or only vaguely similar.

        Output only valid JSON matching:
        {"fields":[{"fieldId":1,"value":"...","confidence":0.97,"source":"document"}]}
        """;

    public async Task<MergedFieldCollection> BuildAsync(
        IReadOnlyList<AgreementTemplateField> templateFields,
        IReadOnlyDictionary<int, string> labels,
        IReadOnlyDictionary<int, string> conversationMemory,
        IEnumerable<UploadedDocument> documents,
        UserProfile? accountProfile,
        CancellationToken cancellationToken = default)
    {
        var merged = new Dictionary<int, MergedFieldValue>();

        var documentFields = MergeDocumentFields(documents);
        var profileFields = BuildProfileFields(accountProfile);

        if (documentFields.Count == 0 && profileFields.Count == 0)
            return new MergedFieldCollection(merged);

        // NeverAsk fields (notary metadata, party identity/passport details)
        // are filled exclusively via AccountProfile/SecondPartyQr, never
        // from documents - excluding them from the catalog keeps the model
        // from ever mapping an unrelated document value (e.g. a vehicle
        // registration number) onto a passport/notary field.
        var askableFieldIds = FieldEligibilityEngine.Classify(templateFields, labels)
            .Where(f => f.Category != FieldCategory.NeverAsk)
            .Select(f => f.FieldId)
            .ToHashSet();

        var catalog = templateFields
            .Where(f => labels.ContainsKey(f.FieldId) && askableFieldIds.Contains(f.FieldId))
            .Select(f => new { fieldId = f.FieldId, label = labels[f.FieldId] })
            .ToList();

        if (catalog.Count == 0)
            return new MergedFieldCollection(merged);

        var payload = new
        {
            field_catalog = catalog,
            existing_answers = conversationMemory.ToDictionary(kv => kv.Key.ToString(), kv => kv.Value),
            document_fields = documentFields.ToDictionary(
                kv => kv.Key,
                kv => new { value = kv.Value.Value, confidence = kv.Value.Confidence, source = "document" }),
            account_profile = profileFields.ToDictionary(
                kv => kv.Key,
                kv => new { value = kv.Value, confidence = 1.0, source = "account_profile" }),
        };

        var userMessage = JsonSerializer.Serialize(payload);
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);

        foreach (var field in Parse(raw))
        {
            if (askableFieldIds.Contains(field.FieldId))
                Put(merged, field);
        }

        return new MergedFieldCollection(merged);
    }

    private static Dictionary<string, ExtractedFieldValue> MergeDocumentFields(IEnumerable<UploadedDocument> documents)
    {
        var merged = new Dictionary<string, ExtractedFieldValue>(StringComparer.OrdinalIgnoreCase);

        foreach (var document in documents.Where(d => d.Status == DocumentProcessingStatus.Processed))
        {
            foreach (var (key, field) in ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson))
            {
                if (field.Confidence < MinimumUsableConfidence || string.IsNullOrWhiteSpace(field.Value))
                    continue;

                if (!merged.TryGetValue(key, out var existing) || field.Confidence > existing.Confidence)
                    merged[key] = field;
            }
        }

        return merged;
    }

    private static Dictionary<string, string> BuildProfileFields(UserProfile? profile)
    {
        if (profile is null)
            return [];

        var fields = new Dictionary<string, string>();
        Add(fields, "profile_full_name", profile.FullName);
        Add(fields, "profile_passport_number", profile.PassportNumber);
        Add(fields, "profile_birth_date", profile.BirthDate);
        Add(fields, "profile_address", profile.Address);
        return fields;
    }

    private static void Add(Dictionary<string, string> fields, string key, string value)
    {
        if (!string.IsNullOrWhiteSpace(value))
            fields[key] = value;
    }

    private static void Put(Dictionary<int, MergedFieldValue> merged, MergedFieldValue incoming)
    {
        if (incoming.FieldId <= 0 || string.IsNullOrWhiteSpace(incoming.Value))
            return;

        if (!merged.TryGetValue(incoming.FieldId, out var existing) || incoming.Confidence > existing.Confidence)
            merged[incoming.FieldId] = incoming;
    }

    private static IReadOnlyList<MergedFieldValue> Parse(string raw)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("fields", out var fieldsEl) || fieldsEl.ValueKind != JsonValueKind.Array)
                return [];

            var fields = new List<MergedFieldValue>();
            foreach (var item in fieldsEl.EnumerateArray())
            {
                if (!item.TryGetProperty("fieldId", out var idEl) || !idEl.TryGetInt32(out var fieldId))
                    continue;
                if (!item.TryGetProperty("value", out var valueEl) || valueEl.ValueKind != JsonValueKind.String)
                    continue;

                var value = valueEl.GetString();
                if (string.IsNullOrWhiteSpace(value))
                    continue;

                var confidence = item.TryGetProperty("confidence", out var confEl) && confEl.TryGetDouble(out var conf)
                    ? Math.Clamp(conf, 0.0, 1.0)
                    : 0.5;
                var source = item.TryGetProperty("source", out var sourceEl) && sourceEl.ValueKind == JsonValueKind.String
                    ? sourceEl.GetString() ?? "unknown"
                    : "unknown";

                fields.Add(new MergedFieldValue(fieldId, value, confidence, source));
            }

            return fields;
        }
        catch (JsonException)
        {
            return [];
        }
    }
}
