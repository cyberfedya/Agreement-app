namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Rotating "Praise" openers for the 3P question shape (Praise/Progress/
/// Proceed). Picked deterministically by turn index rather than left to
/// the model - each interview turn is an independent LLM call with no
/// memory of what it said last time, so without a server-assigned phrase
/// the model has nothing to vary against and reliably defaults to the
/// same word ("Понятно.") every turn.
/// </summary>
public static class AcknowledgementPhrases
{
    private static readonly Dictionary<string, string[]> ByLanguage = new()
    {
        ["ru"] = ["Понятно.", "Отлично.", "Хорошо.", "Спасибо.", "Ясно.", "Принято."],
        ["uz"] = ["Тушунарли.", "Аъло.", "Яхши.", "Рахмат."],
        ["en"] = ["Got it.", "Great.", "Understood.", "Thanks."],
    };

    public static string Pick(string language, int turnIndex)
    {
        var options = ByLanguage.TryGetValue(language, out var forLanguage) ? forLanguage : ByLanguage["ru"];
        return options[turnIndex % options.Length];
    }
}
