using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Deterministically maps document-extracted fields onto template field
/// ids by keyword, with zero LLM involvement - runs before
/// <see cref="QuestionGenerator"/> ever sees the field, so a value found
/// here can never be dropped by an incomplete model response.
///
/// This only covers the stable canonical vocabulary
/// <c>VisionDocumentAnalysisService</c> is instructed to use (vin, brand,
/// model, year, engine_number, plate_number, cadastre_number, area, ...).
/// Anything not covered by a rule here still falls through to
/// <see cref="QuestionGenerator"/>'s narrower, per-question LLM matching -
/// this is a high-confidence fast path, not a replacement for it.
/// </summary>
public static class DocumentFieldMapper
{
    public sealed record Mapping(int FieldId, string Value, string Source, double Confidence, IReadOnlyList<string> HintKeys);
    // Ordered by specificity where labels could otherwise collide (e.g.
    // "берилган сана" alone would also match inside a longer phrase, so
    // the more specific phrase must be listed - and checked - first).
    private static readonly (string[] LabelKeywords, string[] HintKeys, bool JoinValues)[] Rules =
    [
        (["кузов рақами", "кузов раками"], ["vin", "body_number"], false),
        (["шасси рақами", "шасси раками"], ["chassis_number"], false),
        (["двигатель рақами", "двигател рақами"], ["engine_number"], false),
        (["от кучи", "қуввати"], ["engine_power", "engine_capacity"], false),
        (["давлат рақам белгиси", "давлат рақами"], ["plate_number"], false),
        (["ишлаб чиқарилган йил"], ["year"], false),
        (["автотранспорт русуми", "русуми (марка"], ["brand", "model"], true),
        (["гувоҳномасининг серия", "гувоҳномаси серия"], ["registration_number"], false),
        (["гувоҳномаси берилган сана", "гувоҳномасини берилган сана"], ["issue_date"], false),
        (["кадастр"], ["cadastre_number"], false),
        (["майдони"], ["area"], false),
        (["хоналар сони"], ["rooms"], false),
        (["қавати"], ["floor"], false),
    ];

    // Stable English aliases are kept separate from the source-language
    // rules so translated templates use the same deterministic mapper.
    private static readonly (string[] LabelKeywords, string[] HintKeys, bool JoinValues)[] EnglishRules =
    [
        (["vehicle vin", "vin number"], ["vin", "body_number"], false),
        (["vehicle make", "vehicle model"], ["brand", "model"], true),
        (["vehicle year", "manufacture year"], ["year"], false),
        (["plate number", "vehicle plate"], ["plate_number"], false),
        (["cadastre number"], ["cadastre_number"], false),
        (["price", "sale price", "amount"], ["normalized_amount", "price", "amount"], false),
    ];

    /// <summary>
    /// Writes every high-confidence deterministic match straight into
    /// <paramref name="answers"/>. Never overwrites a field the user (or
    /// an earlier turn) already answered. Ambiguous fields with no rule
    /// here (e.g. "who issued this" when a document has two differently
    /// named issuing authorities) are deliberately left alone for
    /// QuestionGenerator's per-question matching instead of guessing.
    /// </summary>
    public static void ApplyMatches(
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        DocumentFieldHintCollection hints,
        Dictionary<int, string> answers)
    {
        foreach (var mapping in FindMatches(fields, labels, hints, answers.Keys))
            answers[mapping.FieldId] = mapping.Value;
    }

    /// <summary>
    /// Produces the deterministic mapping decision without mutating the
    /// answer set. This is shared by the interview, review API and
    /// generation path so all surfaces explain the same result.
    /// </summary>
    public static IReadOnlyList<Mapping> FindMatches(
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        DocumentFieldHintCollection hints,
        IEnumerable<int>? existingFieldIds = null)
    {
        if (hints.Fields.Count == 0)
            return [];

        var existing = existingFieldIds?.ToHashSet() ?? [];
        var hintByKey = new Dictionary<string, DocumentFieldHint>(StringComparer.OrdinalIgnoreCase);
        foreach (var hint in hints.Fields)
        {
            if (!hintByKey.ContainsKey(hint.Key))
                hintByKey[hint.Key] = hint;
        }

        var matches = new List<Mapping>();
        foreach (var field in fields)
        {
            if (existing.Contains(field.FieldId))
                continue;
            if (!labels.TryGetValue(field.FieldId, out var label) || label.Length == 0)
                continue;

            var lower = label.ToLowerInvariant();

            foreach (var (labelKeywords, hintKeys, joinValues) in Rules.Concat(EnglishRules))
            {
                if (!labelKeywords.Any(lower.Contains))
                    continue;

                var values = hintKeys
                    .Select(key => hintByKey.GetValueOrDefault(key))
                    .Where(hint => hint is not null && !string.IsNullOrWhiteSpace(hint.Value))
                    .Cast<DocumentFieldHint>()
                    .ToList();

                if (values.Count == 0)
                    break; // Label matched a rule but the document has no data for it - leave for the LLM path.

                var chosen = joinValues ? values : [values[0]];
                matches.Add(new Mapping(
                    field.FieldId,
                    string.Join(" ", chosen.Select(value => value.Value)),
                    chosen[0].Source,
                    chosen.Min(value => value.Confidence),
                    chosen.Select(value => value.Key).ToList()));
                break;
            }
        }

        return matches;
    }
}
