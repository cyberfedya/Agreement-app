using System.Runtime.CompilerServices;
using System.Text.Json;
using EasyAgree.Infrastructure.Persistence.Seed.Models;

namespace EasyAgree.Infrastructure.Persistence.Seed;

/// <summary>
/// Recursively discovers and deserializes agreement JSON files. Read-only:
/// this never writes back to the source files.
/// </summary>
public sealed class AgreementJsonLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public IReadOnlyList<string> DiscoverFiles(string rootPath)
    {
        if (!Directory.Exists(rootPath))
            throw new DirectoryNotFoundException($"Agreements source folder not found: {rootPath}");

        return Directory.EnumerateFiles(rootPath, "*.json", SearchOption.AllDirectories).ToList();
    }

    public async IAsyncEnumerable<AgreementLoadResult> LoadAsync(
        IReadOnlyList<string> filePaths,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        foreach (var path in filePaths)
        {
            cancellationToken.ThrowIfCancellationRequested();

            AgreementJsonModel? model = null;
            string? readError = null;
            try
            {
                await using var stream = File.OpenRead(path);
                model = await JsonSerializer.DeserializeAsync<AgreementJsonModel>(stream, JsonOptions, cancellationToken);
            }
            catch (Exception ex) when (ex is JsonException or IOException)
            {
                readError = $"Invalid JSON: {ex.Message}";
            }

            if (readError is not null)
            {
                yield return AgreementLoadResult.Failure(path, readError);
                continue;
            }

            var validationError = Validate(model);
            if (validationError is not null)
            {
                yield return AgreementLoadResult.Failure(path, validationError);
                continue;
            }

            yield return AgreementLoadResult.Success(path, model!);
        }
    }

    private static string? Validate(AgreementJsonModel? model)
    {
        if (model is null)
            return "Document is empty or null";
        if (string.IsNullOrWhiteSpace(model.Domain))
            return "Missing required field 'domain'";
        if (string.IsNullOrWhiteSpace(model.Key))
            return "Missing required field 'key'";
        if (string.IsNullOrWhiteSpace(model.HtmlFormat))
            return "Missing required field 'html_format'";

        return null;
    }
}
