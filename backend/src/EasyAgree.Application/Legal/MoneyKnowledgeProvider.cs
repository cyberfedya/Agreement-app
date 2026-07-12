using System.Globalization;
using System.Text.RegularExpressions;

namespace EasyAgree.Application.Legal;

/// <summary>Normalizes explicit, unambiguous USD and UZS amounts without an LLM.</summary>
public sealed partial class MoneyKnowledgeProvider : ILegalKnowledgeProvider
{
    public int Order => 100;
    public string Name => "money";
    public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> knownFacts)
    {
        var results = new List<LegalFact>();
        foreach (var fact in knownFacts)
        {
            if (!TryNormalize(fact.Original, out var amount, out var currency))
                continue;

            results.Add(new("normalized_amount", fact.Original, amount.ToString(CultureInfo.InvariantCulture), 1.0, "normalization", "AUTO", "Deterministic money normalization", [fact.Key]));
            results.Add(new("currency", fact.Original, currency, 1.0, "normalization", "AUTO", "Currency explicitly present in source value", [fact.Key]));
        }
        return results;
    }

    private static bool TryNormalize(string value, out decimal amount, out string currency)
    {
        amount = 0;
        currency = string.Empty;
        var normalized = value.Trim().ToLowerInvariant().Replace(",", string.Empty).Replace(" ", string.Empty);
        var match = AmountRegex().Match(normalized);
        if (!match.Success || !decimal.TryParse(match.Groups["amount"].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out amount))
            return false;
        if (normalized.Contains("thousand")) amount *= 1_000;
        else if (normalized.Contains("mln") || normalized.Contains("million")) amount *= 1_000_000;
        if (normalized.Contains('$') || normalized.Contains("usd") || normalized.Contains("dollar")) currency = "USD";
        else if (normalized.Contains("so'm") || normalized.Contains("uzs")) currency = "UZS";
        else return false;
        return true;
    }

    [GeneratedRegex(@"(?<amount>\d+(?:\.\d+)?)", RegexOptions.CultureInvariant)]
    private static partial Regex AmountRegex();
}
