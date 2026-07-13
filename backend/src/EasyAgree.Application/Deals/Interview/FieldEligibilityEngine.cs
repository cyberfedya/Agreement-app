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
    // Administrative/notarial metadata about the agreement document itself
    // (signing date/place, notary, witnesses, seal, case/registry numbers) -
    // the backend fills these in, or they're irrelevant to a first draft.
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

    // Role-noun prefixes for both parties (seller/buyer, landlord/tenant,
    // lender/borrower, employer/employee, etc.) - whichever party these
    // belong to, their identity fields are covered by AccountProfile
    // (creator, autofilled from the profile) or SecondPartyQr (filled
    // after the counterparty scans the QR code), never asked in the
    // interview itself.
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

    // Identity attributes - passport, ФИО, tax id, contacts, address,
    // birth date, bank details, position - never asked regardless of
    // which party they belong to (AccountProfile / SecondPartyQr).
    private static readonly string[] IdentityAttributeKeywords =
    [
        "паспорт", "ф.и.о", "ф.и.ш",
        "стир", "инн", "телефон", "факс", "электрон почта",
        "яшаш манзил", "проживан",
        "туғилган", "рожден",
        "ҳисоб рақам", "банк", "мфо",
        "лавозим", "ташкилий-ҳуқуқий", "директор", "раҳбар", "руководител",
    ];

    // Technical characteristics nobody knows from memory - engine/chassis/
    // body numbers, engine power and displacement, weight, seating,
    // emissions class, fuel, manufacturer. These come exclusively from an
    // uploaded document (tech passport, cadastre, ...); the interview must
    // never ask them out loud, and their absence must never block a draft.
    // Deliberately does NOT include VIN, brand, model, year or plate
    // number - owners genuinely know those, and VIN stays askable when the
    // template requires it and no document covers it.
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

    // Metadata about the vehicle/trailer's own registration certificate
    // ("техпаспорт" - which department issued it, when, and its series or
    // number) - printed on the physical certificate itself, never
    // something an owner recalls unprompted, so it gets the same
    // DocumentOnly treatment as engine/chassis numbers above. An audit of
    // every agreements/vehicle/*.json template found these phrased around
    // "гувоҳнома" (also spelled "гувохнома" - missing the ҳ diacritic - in
    // several templates) rather than the literal word "техпаспорт", so
    // they weren't caught by TechnicalDocumentOnlyKeywords or the
    // "техпаспорт" entry in LegalDefaultKeywords. A few sibling fields in
    // vehicle_exchange_agreement.json describe the same certificate
    // without the word "гувоҳнома" at all ("Автотранспортнинг ким
    // томонидан берилган" / "...берилган сана"), so those exact phrases
    // are matched directly, scoped to "автотранспорт" so they can't catch
    // unrelated issuance dates (e.g. a power of attorney's own issue date)
    // elsewhere in the same or other templates.
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

    // Commercial terms - price, payment, salary, interest, fees - used to
    // prioritize eligible required fields, not to exclude them.
    private static readonly string[] CommercialKeywords =
    [
        "нарх", "баҳо", "ҳақ", "ҳақи", "қиймат", "стоимост", "цена",
        "сумма", "миқдор", "оплат", "тўлов", "маош", "иш ҳақи", "зарплат",
        "фоиз", "процент", "комиссия", "взнос", "рассроч", "платеж",
    ];

    // Dates/durations that materially change the agreement (transfer,
    // start, repayment, lease term) - used for priority only.
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

        // "гувоҳнома" (certificate/license - birth certificate, registration
        // certificate, trademark certificate, etc.) shares a prefix with
        // "гувоҳ" (witness) but means something entirely different and is
        // often a genuinely required field. Strip it before the witness
        // check so certificate fields aren't wrongly swallowed.
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
