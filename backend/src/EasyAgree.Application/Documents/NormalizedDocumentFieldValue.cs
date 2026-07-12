namespace EasyAgree.Application.Documents;

/// <summary>
/// A post-extraction value. Unlike <see cref="ExtractedFieldValue"/>, this
/// layer never replaces raw OCR/Vision output and records why the effective
/// value differs from the source document.
/// </summary>
public sealed record NormalizedDocumentFieldValue(
    string Value,
    double Confidence,
    string Source,
    string Status,
    string? RawKey = null);
