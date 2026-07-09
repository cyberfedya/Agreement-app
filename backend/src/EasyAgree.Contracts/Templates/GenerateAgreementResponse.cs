namespace EasyAgree.Contracts.Templates;

public sealed record GenerateAgreementResponse(string Key, string Html, DateTime GeneratedAt, string? SecondPartyName = null);
