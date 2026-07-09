namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Clusters consecutive same-category fields (already priority-ordered)
/// into small groups so the question generator can ask about them
/// together in one natural sentence instead of one-at-a-time.
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
            if (last is not null && last[0].Category == field.Category && last.Count < MaxGroupSize)
                last.Add(field);
            else
                groups.Add([field]);
        }

        return groups;
    }
}
