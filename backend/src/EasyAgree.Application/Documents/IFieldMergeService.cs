using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Documents;

public interface IFieldMergeService
{
    /// <summary>
    /// Builds the single field map the interview is allowed to use.
    /// Documents, conversation memory, and profile values are merged before
    /// any next-question selection happens; highest confidence wins.
    /// </summary>
    Task<MergedFieldCollection> BuildAsync(
        IReadOnlyList<AgreementTemplateField> templateFields,
        IReadOnlyDictionary<int, string> labels,
        IReadOnlyDictionary<int, string> conversationMemory,
        IEnumerable<UploadedDocument> documents,
        UserProfile? accountProfile,
        CancellationToken cancellationToken = default);
}
