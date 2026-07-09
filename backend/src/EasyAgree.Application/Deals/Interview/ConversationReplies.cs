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

    public static string Resume(string language) => language switch
    {
        "uz" => "Давом этамиз.",
        "en" => "Let's continue.",
        _ => "Продолжим оформление.",
    };

    /// <summary>
    /// Used only when the model call for a question fails/returns nothing
    /// even after a retry - deliberately generic rather than falling back
    /// to the field's raw template label, which is always Uzbek-only
    /// (templates have no per-field translations) and would silently leak
    /// the wrong language into an otherwise-localized interview.
    /// </summary>
    public static string GenericFallbackQuestion(string language) => language switch
    {
        "uz" => "Кечирасиз, яна бир марта: шартнома учун яна қандай маълумот керак?",
        "en" => "Sorry, could you tell me a bit more about that for the agreement?",
        _ => "Извините, уточните, пожалуйста, эту деталь для договора ещё раз.",
    };
}
