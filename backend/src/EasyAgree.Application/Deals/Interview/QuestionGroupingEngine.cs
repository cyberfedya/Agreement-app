namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Clusters only semantically related fields into one question. Category
/// alone is not enough: two object fields may describe entirely unrelated
/// parts of an agreement. Keeping this deterministic prevents a model from
/// inventing an over-broad multi-question prompt.
/// </summary>
public static class QuestionGroupingEngine
{
    private const int MaxGroupSize = 2;

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

    /// <summary>
    /// Real template field labels are Uzbek/Russian (the interview's actual
    /// question text, generated from them, follows suit) - the English-only
    /// keyword lists here matched nothing in production, silently defeating
    /// grouping for every real deal and turning what should be one combined
    /// question into several separate ones. Keeping both languages so
    /// English test fixtures keep working too.
    /// </summary>
    private static FieldTopic Topic(string label)
    {
        var lower = label.ToLowerInvariant();
        if (ContainsAny(lower, "vin", "vehicle", "car", "plate", "engine", "chassis", "body", "brand", "model", "manufacture year",
                "автотранспорт", "автомашина", "автомобил", "русуми", "давлат рақам", "госномер", "гос. номер"))
            return FieldTopic.Vehicle;
        if (ContainsAny(lower, "cadastre", "property", "address", "area", "room", "floor", "apartment", "building",
                "кадастр", "манзил", "адрес", "уй", "хонадон", "квартир", "этаж", "бино"))
            return FieldTopic.Property;
        if (ContainsAny(lower, "price", "amount", "payment", "bank account", "interest", "installment", "salary",
                "нарх", "баҳо", "қиймат", "стоимост", "цена", "сумма", "тўлов", "оплат", "фоиз", "процент", "рассроч", "маош"))
            return FieldTopic.Payment;
        if (ContainsAny(lower, "date", "deadline", "term", "duration", "repayment", "start", "end",
                "сана", "муддат", "срок", "дата", "бошлан", "тугаш"))
            return FieldTopic.Timing;
        if (ContainsAny(lower, "service", "work", "goods", "product", "delivery",
                "хизмат", "маҳсулот", "товар", "топшир"))
            return FieldTopic.Subject;

        return FieldTopic.Unknown;
    }

    private static bool ContainsAny(string value, params string[] keywords) => keywords.Any(value.Contains);

    private enum FieldTopic { Unknown, Vehicle, Property, Payment, Timing, Subject }
}
