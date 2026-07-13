namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Orders askable fields the way a lawyer would raise them: what the
/// agreement is about first, then logistics (dates), then money last -
/// price and payment terms are only asked once everything else about the
/// deal is already settled, not up front.
/// </summary>
public static class QuestionPriorityEngine
{
    public static IReadOnlyList<ClassifiedField> Order(IEnumerable<ClassifiedField> fields) =>
        fields.OrderBy(f => Rank(f.Category)).ThenBy(f => f.FieldId).ToList();

    private static int Rank(FieldCategory category) => category switch
    {
        FieldCategory.RequiredObject => 0,
        FieldCategory.RequiredTime => 1,
        FieldCategory.RequiredCommercial => 2,
        FieldCategory.Optional => 3,
        _ => 4,
    };
}
