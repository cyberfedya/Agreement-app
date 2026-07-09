namespace EasyAgree.Contracts.Documents;

public sealed record RequiredDocumentDto(
    string Type, string Title, string Description, bool Required, int Priority);
