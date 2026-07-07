namespace EasyAgree.Infrastructure.Persistence.Seed.Models;

/// <summary>Outcome of parsing+validating a single agreement JSON file.</summary>
public sealed class AgreementLoadResult
{
    public required string FilePath { get; init; }

    public bool IsSuccess { get; init; }

    public string? Error { get; init; }

    public AgreementJsonModel? Model { get; init; }

    public static AgreementLoadResult Success(string filePath, AgreementJsonModel model) =>
        new() { FilePath = filePath, IsSuccess = true, Model = model };

    public static AgreementLoadResult Failure(string filePath, string error) =>
        new() { FilePath = filePath, IsSuccess = false, Error = error };
}
