namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Deterministic conditional-field rules. It runs before every planning
/// pass, so an answer received after an earlier question can immediately
/// make downstream questions obsolete.
/// </summary>
public static class FieldDependencyEngine
{
    public static bool IsObsolete(
        ClassifiedField candidate,
        IReadOnlyDictionary<int, string> answers,
        IReadOnlyDictionary<int, string> labels)
    {
        var candidateLabel = candidate.Label.ToLowerInvariant();

        // A cash payment has no bank transfer details. Do not ask for an
        // account, bank name, or bank requisites once that choice is known.
        if (ContainsAny(candidateLabel, "bank account", "bank name", "bank details", "bank requisites", "iban") &&
            answers.Any(answer =>
                labels.TryGetValue(answer.Key, out var label) &&
                ContainsAny(label.ToLowerInvariant(), "payment method", "method of payment", "payment type") &&
                IsCash(answer.Value)))
        {
            return true;
        }

        return false;
    }

    private static bool IsCash(string value) => ContainsAny(value.ToLowerInvariant(), "cash", "налич", "naqd");

    private static bool ContainsAny(string value, params string[] keywords) => keywords.Any(value.Contains);
}
