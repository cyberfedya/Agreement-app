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
        if (hints.Fields.Count == 0)
            return;

        var hintByKey = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var hint in hints.Fields)
        {
            if (!hintByKey.ContainsKey(hint.Key))
                hintByKey[hint.Key] = hint.Value;
        }

        foreach (var field in fields)
        {
            if (answers.ContainsKey(field.FieldId))
                continue;
            if (!labels.TryGetValue(field.FieldId, out var label) || label.Length == 0)
                continue;

            var lower = label.ToLowerInvariant();

            foreach (var (labelKeywords, hintKeys, joinValues) in Rules)
            {
                if (!labelKeywords.Any(lower.Contains))
                    continue;

                var values = hintKeys
                    .Select(key => hintByKey.TryGetValue(key, out var value) ? value : null)
                    .Where(value => !string.IsNullOrWhiteSpace(value))
                    .ToList();

                if (values.Count == 0)
                    break; // Label matched a rule but the document has no data for it - leave for the LLM path.

                answers[field.FieldId] = joinValues ? string.Join(" ", values) : values[0]!;
                break;
            }
        }
    }
}
