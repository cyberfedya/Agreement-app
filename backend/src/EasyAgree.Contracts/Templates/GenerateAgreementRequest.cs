namespace EasyAgree.Contracts.Templates;

public sealed record GenerateAgreementRequest(Dictionary<int, string>? Answers);
