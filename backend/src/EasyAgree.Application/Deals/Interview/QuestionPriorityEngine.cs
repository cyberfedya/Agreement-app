namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Orders askable fields the way a lawyer would raise them: what the
/// agreement is about first, then money (price/payment usually follows
/// naturally right after identifying the subject - a seller expects to be
/// asked "for how much?" almost immediately, not at the very end), then
/// dates/logistics. This is only a default priority for whichever fields
/// are still unanswered - if the price was already stated up front (e.g.
/// "selling my Camry for $10000"), it's extracted on the first turn and
/// never reaches this ordering at all.
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
