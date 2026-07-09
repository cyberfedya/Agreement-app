namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Short, rotating sign-off lines for when the interview has everything it
/// needs - said once, deterministically, with no extra LLM call. Picked
/// pseudo-randomly (not sequentially) so the same deal doesn't always land
/// on the same phrase, but there's nothing to keep in sync across turns.
/// </summary>
public static class ClosingPhrases
{
    private static readonly Dictionary<string, string[]> ByLanguage = new()
    {
        ["ru"] =
        [
            "Спасибо. Этой информации уже достаточно, чтобы подготовить проект договора.",
            "Отлично. Все необходимые сведения собраны. Сейчас подготовлю черновик договора.",
            "Спасибо. Мы собрали всё необходимое. Приступаю к формированию проекта договора.",
        ],
        ["uz"] =
        [
            "Рахмат. Шартнома лойиҳасини тайёрлаш учун бу маълумотлар етарли.",
            "Аъло. Барча зарур маълумотлар тўпланди. Ҳозир шартнома лойиҳасини тайёрлайман.",
        ],
        ["en"] =
        [
            "Thank you. That's everything needed to prepare a draft agreement.",
            "Great, I have everything I need. Preparing the draft now.",
        ],
    };

    public static string Pick(string language)
    {
        var options = ByLanguage.TryGetValue(language, out var forLanguage) ? forLanguage : ByLanguage["ru"];
        return options[Random.Shared.Next(options.Length)];
    }
}
