namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Static, non-LLM phrases for conversation branches that don't need a
/// generated answer - just a polite redirect back to the interview.
/// </summary>
public static class ConversationReplies
{
    public static string OffTopicRedirect(string language) => language switch
    {
        "uz" => "Аввал шартномани расмийлаштиришни якунлайлик, кейин бу саволга ҳам жавоб бераман.",
        "en" => "Let's finish preparing the agreement first - happy to get into that afterwards.",
        _ => "Давайте сначала закончим оформление договора. После этого с удовольствием отвечу и на этот вопрос.",
    };

    public static string ChangeTopicNotice(string language) => language switch
    {
        "uz" => "Бошқа турдаги шартнома керак бўлса, бош экрандан янги сўров билан бошланг - жорий жараён сақланиб қолади.",
        "en" => "To switch to a different kind of agreement, start a new request from the home screen - your progress here is kept.",
        _ => "Если хотите оформить другой договор, начните новый запрос с главного экрана - текущий прогресс сохранится.",
    };

    public static string CancelNotice(string language) => language switch
    {
        "uz" => "Ҳозирча давом этамиз - бекор қилиш ёки бошидан бошлаш учун бош экранга қайтишингиз мумкин.",
        "en" => "Let's continue for now - you can head back to the home screen if you'd like to cancel or start over.",
        _ => "Пока продолжим - если хотите отменить или начать заново, можно вернуться на главный экран.",
    };

    /// <summary>
    /// Shown when the user says they don't know/don't have the fact just
    /// asked - acknowledges it instead of silently re-asking, points at the
    /// uploaded-document path as a way to still answer, and repeats the
    /// question. The field is deliberately left unanswered rather than
    /// filled with the literal "I don't know".
    /// </summary>
    public static string DontKnowNotice(string language) => language switch
    {
        "uz" => "Ҳечқиси йўқ - агар қўлингизда тегишли ҳужжат бўлса, унинг суратини юклаб қўйишингиз мумкин, шунда бу маълумотни ўзим топиб оламан. Акс ҳолда, имкон қадар аниқроқ жавоб беришга ҳаракат қилинг.",
        "en" => "No problem - if you have the relevant document handy, you can upload a photo of it and I'll pick this up from there. Otherwise, please give your best answer.",
        _ => "Ничего страшного - если под рукой есть соответствующий документ, можно загрузить его фото, и я сам найду там эту информацию. Либо попробуйте ответить как можно точнее.",
    };

    /// <summary>
    /// Said once, briefly, when the user doesn't know/can't check a fact
    /// right now, right before moving on to the next question - unlike
    /// <see cref="DontKnowNotice"/> this is never followed by the same
    /// question again, so it stays short instead of re-explaining the
    /// document-upload path every time.
    /// </summary>
    private static readonly Dictionary<string, string[]> DeferredAcknowledgementByLanguage = new()
    {
        ["ru"] =
        [
            "Ничего страшного.",
            "Это можно будет проверить по документу.",
            "Если позже загрузите документ, мы заполним эти данные автоматически.",
        ],
        ["uz"] =
        [
            "Ҳечқиси йўқ.",
            "Буни ҳужжат орқали текшириб кўрса бўлади.",
            "Кейинроқ ҳужжат юкласангиз, бу маълумотлар ўзи тўлдирилади.",
        ],
        ["en"] =
        [
            "No worries.",
            "We can check that from a document later.",
            "If you upload a document later, we'll fill this in automatically.",
        ],
    };

    public static string DeferredAcknowledgement(string language)
    {
        var options = DeferredAcknowledgementByLanguage.TryGetValue(language, out var forLanguage)
            ? forLanguage
            : DeferredAcknowledgementByLanguage["ru"];
        return options[Random.Shared.Next(options.Length)];
    }

    public static string Resume(string language) => language switch
    {
        "uz" => "Давом этамиз.",
        "en" => "Let's continue.",
        _ => "Продолжим оформление.",
    };

    /// <summary>
    /// Used only when the model call for a question fails/returns nothing
    /// even after a retry. Always names the field via its template label,
    /// run through <see cref="FieldLabelTranslator"/> first - the label is
    /// stored in Uzbek only (templates have no per-field translations), so
    /// without translating it this read as a stray untranslated question,
    /// and as the *same* field being asked twice in two different
    /// languages when it followed a properly-phrased ru/en question. An
    /// unmatched label still falls back to the raw Uzbek text - a concrete
    /// answerable question in the wrong language beats the previous fully
    /// generic "уточните эту деталь ещё раз", which named nothing.
    /// </summary>
    public static string FallbackQuestion(string language, string fieldLabel)
    {
        var translated = FieldLabelTranslator.Translate(fieldLabel, language);
        return language switch
        {
            "uz" => $"Илтимос, киритинг: {translated}",
            "en" => $"Please provide: {translated}",
            _ => $"Укажите, пожалуйста: {translated}",
        };
    }

    /// <summary>
    /// Shown when the answer's shape clearly doesn't match what the field
    /// needs (e.g. no digits at all for a money/date field) - asks for a
    /// concrete value instead of silently accepting it or rephrasing the
    /// same question, per <see cref="AnswerShapeValidator"/>.
    /// </summary>
    public static string AnswerShapeMismatchNotice(string language) => language switch
    {
        "uz" => "Жавобингизда бу майдон учун керакли аниқ маълумот (рақам ёки сана) кўринмаяпти. Илтимос, аниқроқ жавоб беринг:",
        "en" => "That answer doesn't seem to include the specific number or date this field needs. Could you clarify:",
        _ => "В ответе не видно конкретного числа или даты, которые нужны для этого поля. Уточните, пожалуйста:",
    };

    /// <summary>
    /// Prefixes a question that's being repeated verbatim because the
    /// exact same field group was already asked about and still isn't
    /// answered - deliberately reuses the prior wording instead of asking
    /// the model for a fresh rephrasing, which is what previously read to
    /// the user as the interview looping ("Номер дела?" / "Уточните номер
    /// дела." / "Подскажите номер дела." for the same unfilled field).
    /// </summary>
    public static string RepeatedQuestionNotice(string language) => language switch
    {
        "uz" => "Яна бир бор сўрайман:",
        "en" => "Just to come back to this:",
        _ => "Ещё раз уточню:",
    };

    /// <summary>
    /// Strips a leading notice this class itself generated, if present -
    /// the client always echoes back exactly what it last displayed as
    /// <c>currentQuestionText</c>, so without this a second wrong-shaped
    /// answer in a row would wrap an already-noticed question in another
    /// notice, stacking indefinitely on repeated wrong answers.
    /// </summary>
    public static string StripLeadingNotice(string language, string questionText)
    {
        var deferredOptions = DeferredAcknowledgementByLanguage.TryGetValue(language, out var forLanguage)
            ? forLanguage
            : DeferredAcknowledgementByLanguage["ru"];

        string[] notices =
        [
            AnswerShapeMismatchNotice(language),
            DontKnowNotice(language),
            OffTopicRedirect(language),
            ChangeTopicNotice(language),
            CancelNotice(language),
            .. deferredOptions,
        ];

        foreach (var notice in notices)
        {
            if (questionText.StartsWith(notice, StringComparison.Ordinal))
            {
                var stripped = questionText[notice.Length..].TrimStart();
                if (stripped.Length > 0)
                    return stripped;
            }
        }

        return questionText;
    }
}
