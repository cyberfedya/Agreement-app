namespace EasyAgree.Application.Deals;

/// <summary>Discriminated outcome of finalizing a deal into a generated agreement.</summary>
public sealed class GenerateFromDealResult
{
    public bool IsNotFound { get; private init; }

    public IReadOnlyList<int>? MissingFieldIds { get; private init; }

    public string? Html { get; private init; }

    public static GenerateFromDealResult NotFound() => new() { IsNotFound = true };

    public static GenerateFromDealResult MissingFields(IReadOnlyList<int> fieldIds) =>
        new() { MissingFieldIds = fieldIds };

    public static GenerateFromDealResult Success(string html) => new() { Html = html };
}
