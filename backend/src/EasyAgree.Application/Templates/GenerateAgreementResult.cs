namespace EasyAgree.Application.Templates;

/// <summary>Discriminated outcome of a generate-agreement attempt.</summary>
public sealed class GenerateAgreementResult
{
    public bool IsNotFound { get; private init; }

    public IReadOnlyList<int>? MissingFieldIds { get; private init; }

    public string? Html { get; private init; }

    public static GenerateAgreementResult NotFound() => new() { IsNotFound = true };

    public static GenerateAgreementResult MissingFields(IReadOnlyList<int> fieldIds) =>
        new() { MissingFieldIds = fieldIds };

    public static GenerateAgreementResult Success(string html) => new() { Html = html };
}
