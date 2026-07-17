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
        if (ContainsAny(candidateLabel, "bank account", "bank name", "bank details", "bank requisites", "iban",
                "ҳисоб рақам", "банк реквизит") &&
            answers.Any(answer =>
                labels.TryGetValue(answer.Key, out var label) &&
                IsPaymentMethodLabel(label) &&
                IsCash(answer.Value)))
        {
            return true;
        }

        // The full-payment-by date only matters if the buyer chose
        // installments - once payment method is known and it isn't
        // installments, this field is moot.
        if (ContainsAny(candidateLabel, "full payment", "полная оплата", "тўлиқ тўлов", "рассроч") &&
            answers.Any(answer =>
                labels.TryGetValue(answer.Key, out var label) &&
                IsPaymentMethodLabel(label) &&
                !IsInstallment(answer.Value)))
        {
            return true;
        }

        // A single unit's floor number only applies to an apartment; a
        // building's total floor count only applies to a house - both
        // read from the answer to "what's being sold" once it's known.
        // Reusable by any future real-estate-style template that phrases
        // its object field the same way, not just this one contract.
        if (candidateLabel.Contains("қавати") &&
            answers.Any(answer =>
                labels.TryGetValue(answer.Key, out var label) &&
                IsPropertyTypeLabel(label) &&
                !IsApartment(answer.Value)))
        {
            return true;
        }

        if (candidateLabel.Contains("қаватлар сони") &&
            answers.Any(answer =>
                labels.TryGetValue(answer.Key, out var label) &&
                IsPropertyTypeLabel(label) &&
                !IsHouse(answer.Value)))
        {
            return true;
        }

        return false;
    }

    private static bool IsPaymentMethodLabel(string label) =>
        ContainsAny(label.ToLowerInvariant(), "payment method", "method of payment", "payment type", "тўлов", "оплат");

    private static bool IsCash(string value) => ContainsAny(value.ToLowerInvariant(), "cash", "налич", "naqd");

    private static bool IsInstallment(string value) => ContainsAny(value.ToLowerInvariant(), "рассроч", "installment", "bo'lib", "bulib");

    private static bool IsPropertyTypeLabel(string label) =>
        ContainsAny(label.ToLowerInvariant(), "кўчмас мулкнинг номи", "сотилаётган", "property type", "тип недвижимости");

    private static bool IsApartment(string value) => ContainsAny(value.ToLowerInvariant(), "квартир", "хонадон", "apartment");

    private static bool IsHouse(string value) => ContainsAny(value.ToLowerInvariant(), "дом", "уй", "ҳовли", "house");

    private static bool ContainsAny(string value, params string[] keywords) => keywords.Any(value.Contains);
}
