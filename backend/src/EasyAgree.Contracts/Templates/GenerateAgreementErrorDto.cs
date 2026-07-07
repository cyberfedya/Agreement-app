namespace EasyAgree.Contracts.Templates;

public sealed record GenerateAgreementErrorDto(string Error, IReadOnlyList<int> MissingFieldIds);
