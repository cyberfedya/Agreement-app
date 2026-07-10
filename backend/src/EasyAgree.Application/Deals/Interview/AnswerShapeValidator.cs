namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Weak, keyword-driven check for whether an answer even looks like the
/// kind of value its field's label is asking for. Only guards against the
/// clearest mismatches - a money/percent field answered with no digits at
/// all, a date field answered with neither a digit nor a recognizable
/// relative-date word - and is deliberately permissive everywhere else so
/// it never blocks a legitimate answer it simply doesn't understand.
///
/// Reuses the same commercial/time keyword vocabulary as
/// <see cref="FieldEligibilityEngine"/> so a field that's prioritized as
/// commercial/time is validated as money-or-percent/date, respectively.
/// </summary>
public static class AnswerShapeValidator
{
    private static readonly string[] MoneyOrPercentKeywords =
    [
        "нарх", "баҳо", "ҳақ", "ҳақи", "қиймат", "стоимост", "цена",
        "сумма", "миқдор", "оплат", "тўлов", "маош", "иш ҳақи", "зарплат",
        "фоиз", "процент", "комиссия", "взнос", "рассроч", "платеж",
    ];

    private static readonly string[] DateKeywords =
    [
        "сана", "муддат", "срок", "вақт", "дата",
        "бошлан", "тугаш", "топшир",
    ];

    private static readonly string[] RelativeDateWords =
    [
        "сегодня", "бугун", "завтра", "эртага", "послезавтра",
        "бессрочн", "муддатсиз",
        "январ", "феврал", "март", "апрел", "май", "июн",
        "июл", "август", "сентябр", "октябр", "ноябр", "декабр",
    ];

    public static bool LooksPlausible(string label, string answer)
    {
        var text = answer.Trim();
        if (text.Length == 0)
            return false;

        var lowerLabel = label.ToLowerInvariant();

        if (MatchesAny(lowerLabel, MoneyOrPercentKeywords))
            return text.Any(char.IsDigit);

        if (MatchesAny(lowerLabel, DateKeywords))
            return text.Any(char.IsDigit) || MatchesAny(text.ToLowerInvariant(), RelativeDateWords);

        return true;
    }

    private static bool MatchesAny(string text, string[] keywords) => keywords.Any(text.Contains);
}
