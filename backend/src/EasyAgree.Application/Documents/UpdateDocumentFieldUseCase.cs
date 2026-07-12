using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

/// <summary>
/// Lets the user correct a field the AI misread. A manually entered value
/// is trusted completely - confidence 1.0, since a human just looked at
/// the document and typed it themselves.
/// </summary>
public sealed class UpdateDocumentFieldUseCase(
    IUploadedDocumentRepository documentRepository,
    IntakePreprocessingService preprocessingService)
{
    public async Task<bool> ExecuteAsync(
        Guid dealId, Guid documentId, string fieldKey, string value, CancellationToken cancellationToken = default)
    {
        var document = await documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.DealId != dealId)
            return false;

        var fields = NormalizedDocumentFieldsSerializer.Deserialize(document.NormalizedFieldsJson);
        fields[fieldKey] = new NormalizedDocumentFieldValue(
            value,
            1.0,
            "user_override",
            "CONFIRMED",
            fieldKey);
        document.NormalizedFieldsJson = NormalizedDocumentFieldsSerializer.Serialize(fields);

        await documentRepository.UpdateAsync(document, cancellationToken);
        await preprocessingService.RefreshAsync(dealId, cancellationToken);
        return true;
    }
}
