using System.Text.RegularExpressions;

namespace EasyAgree.Application.Legal;

public sealed partial class PropertyKnowledgeProvider : ILegalKnowledgeProvider
{
    public int Order => 400;
    public string Name => "property";
    public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> facts)
    {
        var cadastre = facts.FirstOrDefault(f => f.Key.Contains("cadastre", StringComparison.OrdinalIgnoreCase));
        if (cadastre is null) return [];
        var normalized = NonAlphaNumeric().Replace(cadastre.Original, string.Empty).ToUpperInvariant();
        return normalized.Length < 6 ? [] : [new("cadastre_normalized", cadastre.Original, normalized, 1.0, Name, "AUTO", "Cadastre identifier normalized", [cadastre.Key])];
    }
    [GeneratedRegex("[^A-Za-z0-9]")]
    private static partial Regex NonAlphaNumeric();
}
