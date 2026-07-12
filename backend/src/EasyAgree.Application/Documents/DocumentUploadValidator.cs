namespace EasyAgree.Application.Documents;

/// <summary>
/// Deterministic trust boundary for document uploads. The client-supplied
/// content type and file name are advisory only; the bytes must identify as
/// an image format supported by the vision pipeline before they can be
/// persisted or sent to an AI provider.
/// </summary>
public static class DocumentUploadValidator
{
    public const int MaximumFileCount = 10;
    public const int MaximumFileSizeBytes = 10 * 1024 * 1024;

    public static DocumentUploadValidationResult Validate(IReadOnlyList<UploadedFile> files)
    {
        if (files.Count == 0)
            return Invalid("DOCUMENTS_REQUIRED", "Upload at least one document.");

        if (files.Count > MaximumFileCount)
            return Invalid("TOO_MANY_DOCUMENTS", $"A maximum of {MaximumFileCount} documents can be uploaded at once.");

        for (var index = 0; index < files.Count; index++)
        {
            var result = ValidateFile(files[index]);
            if (!result.IsValid)
                return result with { FileIndex = index };
        }

        return DocumentUploadValidationResult.Valid;
    }

    private static DocumentUploadValidationResult ValidateFile(UploadedFile file)
    {
        if (file.Bytes.Length == 0)
            return Invalid("EMPTY_DOCUMENT", "The uploaded document is empty.");

        if (file.Bytes.Length > MaximumFileSizeBytes)
            return Invalid("DOCUMENT_TOO_LARGE", $"Each document must be {MaximumFileSizeBytes / 1024 / 1024} MB or smaller.");

        var detectedType = DetectContentType(file.Bytes);
        if (detectedType is null)
            return Invalid("UNSUPPORTED_DOCUMENT_TYPE", "Only JPEG, PNG, and WebP documents are supported.");

        if (!string.Equals(NormalizeContentType(file.ContentType), detectedType, StringComparison.Ordinal))
            return Invalid("DOCUMENT_CONTENT_TYPE_MISMATCH", "The declared document type does not match its contents.");

        if (!AllowedExtensionsByContentType[detectedType].Contains(Path.GetExtension(file.FileName)))
            return Invalid("DOCUMENT_EXTENSION_MISMATCH", "The document name does not match its content type.");

        return DocumentUploadValidationResult.Valid;
    }

    private static string? DetectContentType(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
            return "image/jpeg";

        if (bytes.Length >= 8 && bytes[..8].SequenceEqual(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
            return "image/png";

        if (bytes.Length >= 12 && bytes[..4].SequenceEqual("RIFF"u8) && bytes[8..12].SequenceEqual("WEBP"u8))
            return "image/webp";

        return null;
    }

    private static string NormalizeContentType(string? contentType) =>
        contentType?.Split(';', 2)[0].Trim().ToLowerInvariant() ?? string.Empty;

    private static readonly IReadOnlyDictionary<string, HashSet<string>> AllowedExtensionsByContentType =
        new Dictionary<string, HashSet<string>>(StringComparer.Ordinal)
        {
            ["image/jpeg"] = new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg" },
            ["image/png"] = new(StringComparer.OrdinalIgnoreCase) { ".png" },
            ["image/webp"] = new(StringComparer.OrdinalIgnoreCase) { ".webp" },
        };

    private static DocumentUploadValidationResult Invalid(string errorCode, string message) =>
        new(false, errorCode, message, null);
}

public sealed record DocumentUploadValidationResult(bool IsValid, string? ErrorCode, string? Message, int? FileIndex)
{
    public static DocumentUploadValidationResult Valid { get; } = new(true, null, null, null);
}
