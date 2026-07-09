namespace EasyAgree.Application.Common.Interfaces;

/// <summary>Local-disk storage for uploaded documents (not a public URL - files are never served directly).</summary>
public interface IFileStorage
{
    /// <summary>Saves the bytes and returns a storage path to persist on the entity.</summary>
    Task<string> SaveAsync(Guid dealId, Guid documentId, string fileName, byte[] bytes, CancellationToken cancellationToken = default);

    Task<byte[]> ReadAsync(string storagePath, CancellationToken cancellationToken = default);
}
