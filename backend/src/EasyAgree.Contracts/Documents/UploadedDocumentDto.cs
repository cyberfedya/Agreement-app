namespace EasyAgree.Contracts.Documents;

public sealed record UploadedDocumentDto(
    Guid Id,
    string FileName,
    string DocumentType,
    double TypeConfidence,
    string Status,
    string? ErrorMessage,
    IReadOnlyDictionary<string, ExtractedFieldDto> Fields);

public sealed record ExtractedFieldDto(string Value, double Confidence);
