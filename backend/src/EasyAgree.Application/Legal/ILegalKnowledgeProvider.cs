namespace EasyAgree.Application.Legal;

public interface ILegalKnowledgeProvider
{
    int Order { get; }
    string Name { get; }
    IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> knownFacts);
}
