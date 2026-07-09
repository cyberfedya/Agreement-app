using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Documents;

public interface IFieldMergeService
{
    /// <summary>
    /// Merges every processed document's extracted fields into one
    /// deduplicated set (highest confidence wins on key collisions), and
    /// renders it as the context block the interview planner feeds the
    /// model alongside the original free-form request - the same
    /// "already stated, don't ask again" treatment.
    /// </summary>
    string? BuildDocumentContext(IEnumerable<UploadedDocument> documents);
}
