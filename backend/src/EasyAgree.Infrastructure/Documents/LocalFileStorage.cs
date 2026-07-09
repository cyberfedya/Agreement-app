using EasyAgree.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace EasyAgree.Infrastructure.Documents;

public sealed class FileStorageOptions
{
    public const string SectionName = "FileStorage";

    /// <summary>Root directory for uploaded documents - never served directly, read back only by the analysis pipeline.</summary>
    public string UploadsRoot { get; set; } = "/app/uploads";
}

public sealed class LocalFileStorage(IOptions<FileStorageOptions> options) : IFileStorage
{
    private readonly string _root = options.Value.UploadsRoot;

    public async Task<string> SaveAsync(
        Guid dealId, Guid documentId, string fileName, byte[] bytes, CancellationToken cancellationToken = default)
    {
        var dealDir = Path.Combine(_root, dealId.ToString());
        Directory.CreateDirectory(dealDir);

        var extension = Path.GetExtension(fileName);
        var relativePath = Path.Combine(dealId.ToString(), $"{documentId}{extension}");
        var fullPath = Path.Combine(_root, dealId.ToString(), $"{documentId}{extension}");

        await File.WriteAllBytesAsync(fullPath, bytes, cancellationToken);
        return relativePath;
    }

    public Task<byte[]> ReadAsync(string storagePath, CancellationToken cancellationToken = default) =>
        File.ReadAllBytesAsync(Path.Combine(_root, storagePath), cancellationToken);

    public Task DeleteAsync(string storagePath, CancellationToken cancellationToken = default)
    {
        var fullPath = Path.Combine(_root, storagePath);
        if (File.Exists(fullPath))
            File.Delete(fullPath);
        return Task.CompletedTask;
    }
}
