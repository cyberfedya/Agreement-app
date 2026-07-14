using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals.Interview;

public sealed record DocumentFieldConflict(int FieldId, string Label, string UserValue, string DocumentValue);

/// <summary>
/// Auto-filled fields are deliberately not surfaced anywhere in
/// <see cref="Conflicts"/> or a count on the DTO - from the user's side
/// this screen is a document check, never a "we were missing information"
/// admission. Only genuine user-value-vs-document disagreements are ever
/// shown.
/// </summary>
public sealed record DocumentVerificationOutcome(
    IReadOnlyList<DocumentFieldConflict> Conflicts, IReadOnlyDictionary<int, string> AutoFilled);

/// <summary>
/// The final, optional document check offered once the interview is done
/// (only when the user never uploaded anything during it): reconciles
/// what the user typed against what the same deterministic mapping
/// <see cref="DocumentFieldMapper"/> already uses elsewhere extracts from
/// the newly uploaded document. Two outcomes per field, never a question:
/// a genuine disagreement becomes a conflict the user resolves explicitly,
/// and a field the user never answered gets silently filled - there is no
/// third "ask about it" path, because <see cref="InterviewPlanner"/> has
/// already finished and this step must never look like more interview.
/// </summary>
public static class DocumentVerificationEngine
{
    public static DocumentVerificationOutcome Evaluate(
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        IReadOnlyDictionary<int, string> answers,
        DocumentFieldHintCollection hints)
    {
        var matches = DocumentFieldMapper.FindMatches(fields, labels, hints);
        var conflicts = new List<DocumentFieldConflict>();
        var autoFilled = new Dictionary<int, string>();

        foreach (var match in matches)
        {
            if (answers.TryGetValue(match.FieldId, out var userValue))
            {
                if (!ValuesMatch(userValue, match.Value))
                {
                    var label = labels.GetValueOrDefault(match.FieldId, string.Empty);
                    conflicts.Add(new DocumentFieldConflict(match.FieldId, label, userValue, match.Value));
                }
            }
            else
            {
                autoFilled[match.FieldId] = match.Value;
            }
        }

        return new DocumentVerificationOutcome(conflicts, autoFilled);
    }

    private static bool ValuesMatch(string a, string b) =>
        string.Equals(Normalize(a), Normalize(b), StringComparison.Ordinal);

    private static string Normalize(string value) =>
        string.Join(' ', value.Trim().ToLowerInvariant().Split(' ', StringSplitOptions.RemoveEmptyEntries));
}
