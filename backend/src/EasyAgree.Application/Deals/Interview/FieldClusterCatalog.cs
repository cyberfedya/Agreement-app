namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Named clusters of fields that read naturally as ONE combined question
/// even though each is a separate template field - e.g. VIN, engine
/// number, body number and chassis number: a live notary asks these
/// together ("Какой VIN, номер двигателя, кузова и шасси?"), not one at a
/// time. This is the single documented exception to
/// <see cref="QuestionGroupingEngine"/>'s "one question = one topic" rule.
///
/// Data-driven and reusable by any template/domain: to give a future
/// template its own combined-question group, add another entry here - no
/// change needed to <see cref="QuestionGroupingEngine"/> or
/// <see cref="QuestionPriorityEngine"/>, both of which consult this catalog
/// instead of hardcoding vehicle-specific keywords.
/// </summary>
public static class FieldClusterCatalog
{
    private static readonly (string Name, string[] Keywords, int MaxSize)[] Clusters =
    [
        ("vehicle_identifiers", ["vin", "двигатель рақами", "кузов рақами", "шасси рақами"], 4),
    ];

    /// <summary>The cluster this field label belongs to, or null if it isn't part of one.</summary>
    public static string? ClusterOf(string label)
    {
        var lower = label.ToLowerInvariant();
        foreach (var (name, keywords, _) in Clusters)
        {
            if (keywords.Any(lower.Contains))
                return name;
        }

        return null;
    }

    public static int MaxSizeOf(string clusterName) =>
        Clusters.First(c => c.Name == clusterName).MaxSize;
}
