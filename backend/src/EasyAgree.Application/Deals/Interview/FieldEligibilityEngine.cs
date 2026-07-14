using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Classifies every field on a template into the category the interview
/// planner should treat it as. This is the single source of truth for
/// "should this ever be asked about" - question generation never sees a
/// field this engine marks <see cref="FieldCategory.NeverAsk"/>.
///
/// The never-ask keyword lists below are the result of an extensive
/// audit across all 418 templates (see project history) - they are
/// deliberately kept as one combined check to avoid regressing that
/// tuning, just grouped by *why* each group is never asked.
/// </summary>
public static class FieldEligibilityEngine
{
    private static readonly string[] LegalDefaultKeywords =
    [
        "нотариал", "нотариус",
        "гувоҳ", "свидетел",
        "муҳр", "печат",
        "рўйхатга ол", "реестр",
        "иш рақами", "номер дела", "шартнома рақами", "номер договора",
        "тузилган сана", "тузилган вақт", "тузилган жой", "тасдиқланган сана",
        "дата составления", "дата подписания",
        "инвентар", "техник паспорт", "техпаспорт", "техническ паспорт",
    ];
    private static readonly string[] PartyRoleKeywords =
    [
        "сотувчи", "сотиб олувчи", "харидор", "покупател", "продав",
        "ижарага берувчи", "ижарага олувчи", "арендодател", "арендатор",
        "қарз берувчи", "қарз олувчи", "займодав", "заемщик", "заёмщик", "кредитор",
        "иш берувчи", "работодател", "ходим", "работник",
        "буюртмачи", "заказчик", "пудратчи", "подрядчик", "исполнител", "бажарувчи",
        "ҳадя қилувчи", "ҳадя олувчи", "дарител", "одаряем",
        "супруг", "хотин", "турмуш ўртоғ",
        "биринчи томон", "иккинчи томон", "первой стороны", "второй стороны",
        "первая сторона", "вторая сторона", "биринчи тараф", "иккинчи тараф",
        "аризачи", "даъвогарнинг", "жавобгарнинг",
    ];

    private static readonly string[] IdentityAttributeKeywords =
    [
        "паспорт", "ф.и.о", "ф.и.ш",
        "стир", "инн", "телефон", "факс", "электрон почта",
        "яшаш манзил", "проживан",
        "туғилган", "рожден",
        "ҳисоб рақам", "банк", "мфо",
        "лавозим", "ташкилий-ҳуқуқий", "директор", "раҳбар", "руководител",
    ];
    private static readonly string[] TechnicalDocumentOnlyKeywords =
    [
        "двигател", "мотор рақами",
        "шасси", "рама", "рамка рақами",
        "номер кузова", "кузов рақами", "кузов раками",
        "мощност", "лошадин", "от кучи", "қувват",
        "снаряженн", "масса", "вазни", "оғирлиги", "грузоподъем", "юк кўтариш",
        "мест для сидения", "ўриндиқ", "пассажиров",
        "экологич", "экологик",
        "топлив", "ёқилғи", "ёнилғи",
        "изготовител", "ишлаб чиқарувчи",
    ];
    private static readonly string[] RegistrationCertificateKeywords =
    [
        "гувоҳномаси берган", "гувохномаси берган",
        "гувоҳномаси берилган", "гувохномаси берилган",
        "гувоҳномаси қайд", "гувохномаси қайд",
        "гувоҳномасига берилган", "гувохномасига берилган",
        "гувоҳномасининг серия", "гувохномасининг серия",
        "гувоҳномага берилган", "гувохномага берилган",
        "воситасини қайд этиш гувоҳномасининг", "воситасига қайд этиш гувоҳномасининг",
        "автотранспортни қайд этган", "автомашинани қайд этган",
        "автотранспортнинг ким томонидан берилган", "автотранспорт ким томонидан берилган",
        "автотранспортнинг берилган сана", "автотранспорт берилган сана",
        "автотранспорт қайд этилган ҳудуд", "автотранспорт воситаси қайд этилган ҳудуд",
    ];
    private static readonly string[] CommercialKeywords =
    [
        "нарх", "баҳо", "ҳақ", "ҳақи", "қиймат", "стоимост", "цена",
        "сумма", "миқдор", "оплат", "тўлов", "маош", "иш ҳақи", "зарплат",
        "фоиз", "процент", "комиссия", "взнос", "рассроч", "платеж",
    ];
    private static readonly string[] TimeKeywords =
    [
        "сана", "муддат", "срок", "вақт", "дата",
        "бошлан", "тугаш", "топшир",
    ];
    public static IReadOnlyList<ClassifiedField> Classify(
        IEnumerable<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels)
    {
        var result = new List<ClassifiedField>();
        foreach (var field in fields)
        {
            if (!labels.TryGetValue(field.FieldId, out var label) || label.Length == 0)
                continue;

            result.Add(new ClassifiedField(field.FieldId, label, Categorize(field, label)));
        }

        return result;
    }

    private static FieldCategory Categorize(AgreementTemplateField field, string label)
    {
        var lower = label.ToLowerInvariant();
        var legalCheckText = lower.Replace("гувоҳнома", "");

        if (MatchesAny(legalCheckText, LegalDefaultKeywords) || MatchesAny(lower, PartyRoleKeywords) ||
            MatchesAny(lower, IdentityAttributeKeywords))
        {
            return FieldCategory.NeverAsk;
        }

        if (MatchesAny(lower, TechnicalDocumentOnlyKeywords) || MatchesAny(lower, RegistrationCertificateKeywords))
            return FieldCategory.DocumentOnly;

        if (field.Mode == AgreementFieldMode.Optional)
            return FieldCategory.Optional;

        if (MatchesAny(lower, CommercialKeywords))
            return FieldCategory.RequiredCommercial;

        if (MatchesAny(lower, TimeKeywords))
            return FieldCategory.RequiredTime;

        return FieldCategory.RequiredObject;
    }
    private static bool MatchesAny(string lower, string[] keywords) => keywords.Any(lower.Contains);
}