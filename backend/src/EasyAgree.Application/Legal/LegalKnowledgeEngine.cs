using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Legal;

/// <summary>Extensible deterministic enrichment host. Derived values append
/// to the fact set and can never overwrite an existing value.</summary>
public sealed class LegalKnowledgeEngine(IEnumerable<ILegalKnowledgeProvider> providers)
{
    private readonly IReadOnlyList<ILegalKnowledgeProvider> _providers = providers.OrderBy(p => p.Order).ThenBy(p => p.Name, StringComparer.Ordinal).ToList();

    public IReadOnlyList<DocumentFieldHint> Enrich(IReadOnlyList<DocumentFieldHint> hints)
    {
        return EnrichWithReport(hints).Facts
            .Select(f => new DocumentFieldHint(f.Key, f.Normalized, f.Confidence, f.Source)).ToList();
    }

    public LegalKnowledgeReport EnrichWithReport(IReadOnlyList<DocumentFieldHint> hints)
    {
        var facts = hints.Select(h => new LegalFact(h.Key, h.Value, h.Value, h.Confidence, h.Source, "CONFIRMED", "Existing source", [h.Key])).ToList();
        var byKey = facts.ToDictionary(f => f.Key, StringComparer.OrdinalIgnoreCase);
        var conflicts = new List<LegalFactConflict>();
        foreach (var provider in _providers)
            foreach (var derived in provider.Derive(facts))
            {
                var dated = derived with { DerivedAt = derived.DerivedAt ?? DateTime.UtcNow };
                if (byKey.TryGetValue(dated.Key, out var existing))
                {
                    if (!string.Equals(existing.Normalized, dated.Normalized, StringComparison.OrdinalIgnoreCase))
                        conflicts.Add(new(dated.Key, existing.Normalized, dated.Normalized, provider.Name, "Provider result conflicts with an existing fact"));
                    continue;
                }
                byKey[dated.Key] = dated;
                facts.Add(dated);
            }
        return new LegalKnowledgeReport(facts, conflicts);
    }
}
