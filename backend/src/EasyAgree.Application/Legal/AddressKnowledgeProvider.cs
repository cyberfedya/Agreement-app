namespace EasyAgree.Application.Legal;

public sealed class AddressKnowledgeProvider : ILegalKnowledgeProvider
{
    public int Order => 300;
    public string Name => "address";
    public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> facts)
    {
        var address = facts.FirstOrDefault(f => f.Key.Contains("address", StringComparison.OrdinalIgnoreCase));
        if (address is null) return [];
        var city = new[] { "tashkent", "samarkand", "bukhara", "andijan", "fergana", "namangan" }
            .FirstOrDefault(city => address.Original.Contains(city, StringComparison.OrdinalIgnoreCase));
        return city is null ? [] : [new("city", address.Original, city[..1].ToUpperInvariant() + city[1..], 0.99, Name, "AUTO", "City explicitly present in address", [address.Key])];
    }
}
