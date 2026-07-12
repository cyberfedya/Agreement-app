namespace EasyAgree.Application.Legal;

public sealed record LegalFactConflict(string Key, string ExistingValue, string DerivedValue, string Provider, string Reason);
public sealed record LegalKnowledgeReport(IReadOnlyList<LegalFact> Facts, IReadOnlyList<LegalFactConflict> Conflicts);
