using System.Globalization;

namespace EasyAgree.Application.Legal;

/// <summary>Normalizes only ISO dates and explicit relative English dates;
/// ambiguous numeric dates are intentionally left untouched.</summary>
public sealed class DateKnowledgeProvider(TimeProvider timeProvider) : ILegalKnowledgeProvider
{
    public int Order => 500;
    public string Name => "date";

    public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> facts)
    {
        var results = new List<LegalFact>();
        foreach (var fact in facts.Where(f => f.Key.Contains("date", StringComparison.OrdinalIgnoreCase) || f.Key.Contains("deadline", StringComparison.OrdinalIgnoreCase)))
        {
            if (!TryNormalize(fact.Original, out var date)) continue;
            results.Add(new("normalized_" + fact.Key, fact.Original, date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), 1.0, Name, "AUTO", "Deterministic date normalization", [fact.Key]));
        }
        return results;
    }

    private bool TryNormalize(string original, out DateOnly date)
    {
        var value = original.Trim().ToLowerInvariant();
        var today = DateOnly.FromDateTime(timeProvider.GetUtcNow().UtcDateTime);
        if (value == "today") { date = today; return true; }
        if (value == "tomorrow") { date = today.AddDays(1); return true; }
        if (value == "next week") { date = today.AddDays(7); return true; }
        if (value == "end of month") { date = new DateOnly(today.Year, today.Month, DateTime.DaysInMonth(today.Year, today.Month)); return true; }
        if (value == "end of year") { date = new DateOnly(today.Year, 12, 31); return true; }
        return DateOnly.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out date);
    }
}
