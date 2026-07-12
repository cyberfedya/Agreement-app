namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Clusters only semantically related fields into one question. Category
/// alone is not enough: two object fields may describe entirely unrelated
/// parts of an agreement. Keeping this deterministic prevents a model from
/// inventing an over-broad multi-question prompt.
/// </summary>
public static class QuestionGroupingEngine
{
    private const int MaxGroupSize = 3;

    public static IReadOnlyList<IReadOnlyList<ClassifiedField>> BuildGroups(IReadOnlyList<ClassifiedField> ordered)
    {
        var groups = new List<List<ClassifiedField>>();
        foreach (var field in ordered)
        {
            var last = groups.Count > 0 ? groups[^1] : null;
            if (last is not null && last.Count < MaxGroupSize && AreRelated(last[0], field))
                last.Add(field);
            else
                groups.Add([field]);
        }

        return groups;
    }

    private static bool AreRelated(ClassifiedField first, ClassifiedField candidate)
    {
        if (first.Category != candidate.Category)
            return false;

        var firstTopic = Topic(first.Label);
        return firstTopic != FieldTopic.Unknown && firstTopic == Topic(candidate.Label);
    }

    private static FieldTopic Topic(string label)
    {
        var lower = label.ToLowerInvariant();
        if (ContainsAny(lower, "vin", "vehicle", "car", "plate", "engine", "chassis", "body", "brand", "model", "manufacture year"))
            return FieldTopic.Vehicle;
        if (ContainsAny(lower, "cadastre", "property", "address", "area", "room", "floor", "apartment", "building"))
            return FieldTopic.Property;
        if (ContainsAny(lower, "price", "amount", "payment", "bank account", "interest", "installment", "salary"))
            return FieldTopic.Payment;
        if (ContainsAny(lower, "date", "deadline", "term", "duration", "repayment", "start", "end"))
            return FieldTopic.Timing;
        if (ContainsAny(lower, "service", "work", "goods", "product", "delivery"))
            return FieldTopic.Subject;

        return FieldTopic.Unknown;
    }

    private static bool ContainsAny(string value, params string[] keywords) => keywords.Any(value.Contains);

    private enum FieldTopic { Unknown, Vehicle, Property, Payment, Timing, Subject }
}
