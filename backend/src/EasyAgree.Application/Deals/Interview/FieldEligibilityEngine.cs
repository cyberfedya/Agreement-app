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
        "буйруқ рақами", "буйруқ қабул қилинган",
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
        "аризачи", "даъвогарнинг", "жавобгарнинг", "шикоят берувчи",
    ];

    private static readonly string[] IdentityAttributeKeywords =
    [
        "паспорт", "ф.и.о", "ф.и.ш",
        "стир", "инн", "телефон", "факс", "электрон почта",
        "яшаш манзил", "проживан",
        "туғилган", "рожден",
        "ҳисоб рақам", "банк", "мфо",
        "лавозим", "ташкилий-ҳуқуқий", "ташкилий ҳуқуқий", "директор", "раҳбар", "руководител",
        "юридик манзил",
    ];
    // Chassis number is deliberately askable (like engine/kuzov number) -
    // the owner can read it off the vehicle or its documents, and the
    // interview offers a photo-upload alternative alongside the question.
    // "рама"/"рамка рақами" (frame, not the vehicle's own chassis number)
    // stay excluded - those describe deep-technical frame specs nobody
    // knows from memory.
    private static readonly string[] TechnicalDocumentOnlyKeywords =
    [
        "объем двигателя", "объём двигателя", "двигатель ҳажми",
        "рама", "рамка рақами",
        "мощност", "лошадин", "от кучи", "қувват",
        "снаряженн", "масса", "вазни", "оғирлиги", "грузоподъем", "юк кўтариш",
        "мест для сидения", "ўриндиқ", "пассажиров",
        "экологич", "экологик",
        "топлив", "ёқилғи", "ёнилғи",
        "изготовител", "ишлаб чиқарувчи",
    ];
    /// <summary>Reference details of a certificate/license the deal itself
    /// depends on but doesn't create (marriage/birth certificate number and
    /// issue date, an attorney's license number and issuing authority) -
    /// read off that document, not recalled from memory. Distinct from
    /// <see cref="RegistrationCertificateKeywords"/>, which is specifically
    /// about a vehicle's own registration certificate.</summary>
    private static readonly string[] RegistryCertificateKeywords =
    [
        "гувоҳнома рақами", "гувохнома рақами",
        "гувоҳнома берилган сана", "гувохнома берилган сана",
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

            result.Add(new ClassifiedField(field.FieldId, label, Categorize(label)));
        }

        return result;
    }

    private static FieldCategory Categorize(string label)
    {
        var lower = label.ToLowerInvariant();
        var legalCheckText = lower.Replace("гувоҳнома", "");

        // "Ходимга бириктирилаётган автомашина..." (the car assigned TO the
        // employee) is about the car, not the employee's own identity - but
        // it starts with "ходимга", which the bare "ходим" party-role
        // keyword (meant for fields like "Ходимнинг Ф.И.О.") would
        // otherwise also match. Same fix shape as the "гувоҳнома" strip
        // above: remove the specific false-positive phrase before the
        // party-role check, not the keyword itself, so genuine employee-
        // identity fields elsewhere stay correctly excluded.
        var partyRoleCheckText = lower.Replace("ходимга бириктирилаётган", "");

        // "Боланинг Ф.И.О.си"/"...туғилган вақти"/"...яшаш манзили" (the
        // CHILD's name/birth date/address - in custody, alimony, adoption,
        // paternity and school-transfer templates) is the document's actual
        // subject, not a party's own identity the account profile already
        // knows - but it contains "ф.и.о"/"туғилган"/"яшаш манзил" and would
        // otherwise be wrongly excluded by IdentityAttributeKeywords.
        // Unlike the two strips above, "боланинг" isn't a larger phrase that
        // *embeds* the offending keyword as a substring - it's a separate
        // co-occurring word, so stripping it wouldn't remove the keyword
        // match. Skip the identity check entirely instead whenever the
        // label is about the child; every numbered/qualified variant
        // ("1-Боланинг", "Фарзандликка олинувчи боланинг", "иккинчи
        // боланинг") contains the bare "боланинг" substring, so one check
        // covers every phrasing found across the family/education domains.
        var isChildSubjectField = lower.Contains("боланинг");

        if (MatchesAny(legalCheckText, LegalDefaultKeywords) || MatchesAny(partyRoleCheckText, PartyRoleKeywords) ||
            (!isChildSubjectField && MatchesAny(lower, IdentityAttributeKeywords)))
        {
            return FieldCategory.NeverAsk;
        }

        if (MatchesAny(lower, TechnicalDocumentOnlyKeywords) || MatchesAny(lower, RegistrationCertificateKeywords) ||
            MatchesAny(lower, RegistryCertificateKeywords) || IsLicenseReferenceField(lower))
        {
            return FieldCategory.DocumentOnly;
        }

        if (MatchesAny(lower, CommercialKeywords))
            return FieldCategory.RequiredCommercial;

        if (MatchesAny(lower, TimeKeywords))
            return FieldCategory.RequiredTime;

        return FieldCategory.RequiredObject;
    }

    // Bare "лицензия" (rather than a specific suffixed phrase - Uzbek's
    // agglutinative suffixes "лицензия"/"лицензияси"/"лицензиясини"/
    // "лицензиянинг" vary too much for one exact phrase to catch reliably)
    // usually references an existing license read off a document - but a
    // field can also ask for the license itself as the deal's commercial
    // subject (e.g. a franchise agreement's "license fee amount"). Only
    // treat it as document-derived when the label isn't also a price/
    // amount question, so that case still reaches the commercial check
    // below instead of being silently skipped.
    private static bool IsLicenseReferenceField(string lower) =>
        lower.Contains("лицензия") && !MatchesAny(lower, CommercialKeywords);

    private static bool MatchesAny(string lower, string[] keywords) => keywords.Any(lower.Contains);
}