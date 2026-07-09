namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Orders askable fields the way a lawyer would raise them: what the
/// agreement is about first, then money, then dates, then (if ever) the
/// optional extras.
/// </summary>
public static class QuestionPriorityEngine
{
    public static IReadOnlyList<ClassifiedField> Order(IEnumerable<ClassifiedField> fields) =>
        fields.OrderBy(f => Rank(f.Category)).ThenBy(f => f.FieldId).ToList();

    private static int Rank(FieldCategory category) => category switch
    {
        FieldCategory.RequiredObject => 0,
        FieldCategory.RequiredCommercial => 1,
        FieldCategory.RequiredTime => 2,
        FieldCategory.Optional => 3,
        _ => 4,
    };
}
