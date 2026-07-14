namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Template field labels are stored once, in Uzbek (Cyrillic) - templates
/// have no per-field translations. That's invisible during a normal turn,
/// where <see cref="QuestionGenerator"/> always phrases the actual
/// question in the interview's own language regardless of the label's
/// language. It only used to leak when the model call failed even after a
/// retry and <see cref="ConversationReplies.FallbackQuestion"/> had to
/// name the field directly - verbatim in Uzbek, reading as a stray
/// untranslated question, and worse, as the *same* thing being asked
/// twice in two different languages when it followed a properly-phrased
/// ru/en question about the same field.
///
/// Phrase substitution, not full translation: covers the exact labels
/// that actually appear on the vehicle-sale template plus the identity/
/// date fragments shared by most other templates. An unmatched label is
/// returned unchanged - it still reads oddly, but never worse than before
/// this existed, and is forward-compatible with templates not covered
/// here.
/// </summary>
public static class FieldLabelTranslator
{
    private static readonly (string Uzbek, string Ru, string En)[] Phrases =
    [
        ("автотранспорт воситасининг vin рақами", "VIN автомобиля", "vehicle VIN"),
        ("автотранспортнинг двигатель рақами", "номер двигателя автомобиля", "vehicle engine number"),
        ("автотранспортнинг кузов рақами", "номер кузова автомобиля", "vehicle body number"),
        ("автотранспортнинг шасси рақами", "номер шасси автомобиля", "vehicle chassis number"),
        ("автотранспорт воситасининг давлат рақам белгиси", "госномер автомобиля", "vehicle plate number"),
        ("автотранспорт воситасининг от кучи", "мощность двигателя автомобиля", "vehicle engine power"),
        ("автотранспорт воситасининг ранги", "цвет автомобиля", "vehicle color"),
        ("автотранспорт воситасини топшириш санаси", "дата передачи автомобиля", "vehicle transfer date"),
        ("автотранспорт воситасининг маълум носозликлари ёки хусусиятлари", "известные неисправности автомобиля", "known vehicle defects"),
        ("автотранспорт русуми", "марка и модель автомобиля", "vehicle make and model"),
        ("автотранспорт воситаси ишлаб чиқарилган йил", "год выпуска автомобиля", "vehicle manufacture year"),
        ("тарафлар ўзаро келишувига асосан автотранспорт воситасининг қиймати", "цена автомобиля", "vehicle price"),
        ("тўлов қандай амалга оширилади", "способ оплаты", "payment method"),
        ("бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана", "дата полной оплаты при рассрочке", "full payment date for installments"),
        ("сотувчининг манзили", "адрес продавца", "seller's address"),
        ("сотувчининг ф.и.о", "ФИО продавца", "seller's full name"),
        ("сотиб олувчининг манзили", "адрес покупателя", "buyer's address"),
        ("сотиб олувчининг ф.и.о", "ФИО покупателя", "buyer's full name"),
        ("шартнома тузилган сана", "дата заключения договора", "agreement date"),
    ];

    public static string Translate(string label, string language)
    {
        if (language is not ("ru" or "en"))
            return label;

        var lower = label.Trim().ToLowerInvariant();
        foreach (var (uzbek, ru, en) in Phrases)
        {
            if (lower == uzbek)
                return language == "ru" ? ru : en;
        }

        return label;
    }
}
