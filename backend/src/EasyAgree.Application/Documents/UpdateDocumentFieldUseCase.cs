using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

/// <summary>
/// Lets the user correct a field the AI misread. A manually entered value
/// is trusted completely - confidence 1.0, since a human just looked at
/// the document and typed it themselves.
/// </summary>
public sealed class UpdateDocumentFieldUseCase(IUploadedDocumentRepository documentRepository)
{
    public async Task<bool> ExecuteAsync(
        Guid dealId, Guid documentId, string fieldKey, string value, CancellationToken cancellationToken = default)
    {
        var document = await documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.DealId != dealId)
            return false;

        var fields = ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson);
        fields[fieldKey] = new ExtractedFieldValue(value, 1.0);
        document.ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(fields);

        await documentRepository.UpdateAsync(document, cancellationToken);
        return true;
    }
}
