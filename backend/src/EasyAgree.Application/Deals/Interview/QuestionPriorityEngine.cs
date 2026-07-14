namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Orders askable fields the way a live conversation flows: first identify
/// the subject of the deal (object fields), then logistics (dates), then
/// how payment happens, and only at the very end the price itself - the
/// natural close of a negotiation. This is only a default priority for
/// whichever fields are still unanswered: if the price was already stated
/// up front ("selling my Camry for $10000"), it's extracted on the first
/// turn and never reaches this ordering at all.
/// </summary>
public static class QuestionPriorityEngine
{
    /// <summary>Labels that mean the deal's price/value itself, as opposed
    /// to other commercial terms (payment method, installments) that should
    /// be settled before the final number is named.</summary>
    private static readonly string[] PriceKeywords = ["қиймат", "нарх", "баҳолан", "цена", "стоимост"];

    public static IReadOnlyList<ClassifiedField> Order(IEnumerable<ClassifiedField> fields)
    {
        var list = fields.ToList();

        // Fields in the same FieldClusterCatalog cluster (e.g. VIN/engine/
        // kuzov/chassis number) must sort adjacently so QuestionGroupingEngine
        // can combine them into one question - they take the position of
        // the lowest FieldId in their cluster instead of their own.
        var clusterAnchor = list
            .Select(f => (Field: f, Cluster: FieldClusterCatalog.ClusterOf(f.Label)))
            .Where(x => x.Cluster is not null)
            .GroupBy(x => x.Cluster)
            .ToDictionary(g => g.Key!, g => g.Min(x => x.Field.FieldId));

        return list
            .OrderBy(Rank)
            .ThenBy(f => SortKey(f, clusterAnchor))
            .ThenBy(f => f.FieldId)
            .ToList();
    }

    private static int SortKey(ClassifiedField field, IReadOnlyDictionary<string, int> clusterAnchor)
    {
        var cluster = FieldClusterCatalog.ClusterOf(field.Label);
        return cluster is not null && clusterAnchor.TryGetValue(cluster, out var anchor) ? anchor : field.FieldId;
    }

    private static int Rank(ClassifiedField field) => field.Category switch
    {
        FieldCategory.RequiredObject => 0,
        FieldCategory.RequiredTime => 1,
        FieldCategory.RequiredCommercial => IsPrice(field.Label) ? 3 : 2,
        FieldCategory.Optional => 4,
        _ => 5,
    };

    private static bool IsPrice(string label)
    {
        var lower = label.ToLowerInvariant();
        return PriceKeywords.Any(lower.Contains);
    }
}
