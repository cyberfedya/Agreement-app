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

    /// <summary>
    /// Said when the interview stops because it hit its per-domain question
    /// cap (<see cref="InterviewPlanner.MaxQuestionsFor"/>) while some
    /// non-critical fields are still unanswered - distinct from
    /// <see cref="Pick"/>'s "everything's covered" message, since here the
    /// user has a genuine choice to make rather than nothing left to add.
    /// </summary>
    private static readonly Dictionary<string, string> CapReachedByLanguage = new()
    {
        ["ru"] =
            "Договор уже можно сформировать. Остались необязательные сведения. " +
            "Вы можете сформировать договор сейчас или заполнить ещё несколько данных для большей юридической точности.",
        ["uz"] =
            "Шартномани ҳозир тайёрлаш мумкин. Мажбурий бўлмаган маълумотлар қолди. " +
            "Шартномани ҳозир тайёрлашингиз ёки юридик аниқлик учун яна бир нечта маълумот киритишингиз мумкин.",
        ["en"] =
            "The agreement can already be generated. Only optional details remain. " +
            "You can generate it now, or add a few more details for greater legal precision.",
    };

    public static string PickCapReached(string language) =>
        CapReachedByLanguage.TryGetValue(language, out var message) ? message : CapReachedByLanguage["ru"];
}
