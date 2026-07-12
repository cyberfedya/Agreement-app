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
    private readonly string _root = Path.GetFullPath(options.Value.UploadsRoot);
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp",
    };

    public async Task<string> SaveAsync(
        Guid dealId, Guid documentId, string fileName, byte[] bytes, CancellationToken cancellationToken = default)
    {
        var extension = Path.GetExtension(fileName);
        if (!AllowedExtensions.Contains(extension))
            throw new InvalidOperationException("Unsupported file extension for document storage.");

        var dealDir = ResolvePath(dealId.ToString());
        Directory.CreateDirectory(dealDir);

        var relativePath = Path.Combine(dealId.ToString(), $"{documentId}{extension}");
        var fullPath = ResolvePath(relativePath);

        await File.WriteAllBytesAsync(fullPath, bytes, cancellationToken);
        return relativePath;
    }

    public Task<byte[]> ReadAsync(string storagePath, CancellationToken cancellationToken = default) =>
        File.ReadAllBytesAsync(ResolvePath(storagePath), cancellationToken);

    public Task DeleteAsync(string storagePath, CancellationToken cancellationToken = default)
    {
        var fullPath = ResolvePath(storagePath);
        if (File.Exists(fullPath))
            File.Delete(fullPath);
        return Task.CompletedTask;
    }

    private string ResolvePath(string relativePath)
    {
        var fullPath = Path.GetFullPath(Path.Combine(_root, relativePath));
        var rootWithSeparator = _root.EndsWith(Path.DirectorySeparatorChar)
            ? _root
            : _root + Path.DirectorySeparatorChar;

        if (!fullPath.StartsWith(rootWithSeparator, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Document storage path escapes the configured uploads root.");

        return fullPath;
    }
}
