using EasyAgree.Domain.Enums;

namespace EasyAgree.Domain.Entities;

/// <summary>
/// One file uploaded against a <see cref="Deal"/> (a passport photo, a
/// cadastre scan, etc). Classification and field extraction both happen
/// from a single vision-model pass over the file and are persisted here so
/// the interview planner can treat them the same way it treats the
/// original free-form request - already-known information to never ask
/// about again.
/// </summary>
public class UploadedDocument
{
    public Guid Id { get; set; }

    public Guid DealId { get; set; }

    public required string FileName { get; set; }

    public required string ContentType { get; set; }

    /// <summary>Path on disk (relative to the uploads root), not a public URL.</summary>
    public required string StoragePath { get; set; }

    public DocumentType DocumentType { get; set; } = DocumentType.Unknown;

    public double TypeConfidence { get; set; }

    /// <summary>
    /// Semantic key/value/confidence triples read from the document
    /// (e.g. <c>full_name</c>, <c>passport_number</c>, <c>vin</c>),
    /// serialized as JSON. Field keys are free-form on purpose - matching
    /// them to a specific template's field ids is left to the interview
    /// planner's existing natural-language extraction, the same mechanism
    /// already used for the original free-form request.
    /// </summary>
    public string? ExtractedFieldsJson { get; set; }

    /// <summary>
    /// Effective fields created after raw extraction (manual corrections,
    /// deterministic mapping and validation). This is deliberately separate
    /// from <see cref="ExtractedFieldsJson"/> so extraction can be replayed
    /// when mapping rules evolve without calling OCR/Vision again.
    /// </summary>
    public string? NormalizedFieldsJson { get; set; }

    /// <summary>Raw text read off the document - kept for transparency/debugging, not itself fed to the interview.</summary>
    public string? OcrText { get; set; }

    public DocumentProcessingStatus Status { get; set; } = DocumentProcessingStatus.Pending;

    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Set when this document appears to be about a different real-world
    /// subject than what the user already told the system (e.g. a
    /// different car brand) - null otherwise. Purely informational: the
    /// document is still saved and its fields still show up in the
    /// editable-fields sheet, they're just not silently used to fill the
    /// interview.
    /// </summary>
    public string? MismatchWarning { get; set; }

    public DateTime UploadedAt { get; set; }

    public DateTime? ProcessedAt { get; set; }
}
