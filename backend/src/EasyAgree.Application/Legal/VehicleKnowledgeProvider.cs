using System.Text.RegularExpressions;

namespace EasyAgree.Application.Legal;

/// <summary>Conservative VIN and vehicle-identifier enrichment. It only
/// emits facts encoded directly in the identifier, never model guesses.</summary>
public sealed partial class VehicleKnowledgeProvider : ILegalKnowledgeProvider
{
    public int Order => 200;
    public string Name => "vehicle";

    public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> facts)
    {
        var results = new List<LegalFact>();
        var vin = facts.FirstOrDefault(f => f.Key.Equals("vin", StringComparison.OrdinalIgnoreCase));
        if (vin is null) return results;
        var normalized = NonAlphaNumeric().Replace(vin.Original, string.Empty).ToUpperInvariant();
        if (normalized.Length != 17 || normalized.Any(c => "IOQ".Contains(c))) return results;
        results.Add(new("vin_normalized", vin.Original, normalized, 1.0, Name, "AUTO", "VIN normalized from explicit identifier", [vin.Key]));
        var country = normalized[0] switch { 'J' => "JP", 'K' => "KR", 'W' => "DE", 'S' => "GB", 'Z' => "IT", '1' or '4' or '5' => "US", _ => null };
        if (country is not null) results.Add(new("vehicle_country", vin.Original, country, 0.95, Name, "AUTO", "Country region encoded in VIN WMI", [vin.Key]));
        return results;
    }

    [GeneratedRegex("[^A-Za-z0-9]")]
    private static partial Regex NonAlphaNumeric();
}
