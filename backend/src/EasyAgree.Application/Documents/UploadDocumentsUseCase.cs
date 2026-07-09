using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

public sealed record UploadedFile(string FileName, string ContentType, byte[] Bytes);

/// <summary>
/// Saves each uploaded file and runs it through document analysis
/// synchronously before returning - there's no background job queue, so
/// the request simply waits for the vision pass. One failed file doesn't
/// fail the others.
/// </summary>
public sealed class UploadDocumentsUseCase(
    IDealRepository dealRepository,
    IUploadedDocumentRepository documentRepository,
    IFileStorage fileStorage,
    IDocumentAnalysisService analysisService,
    IntakePreprocessingService preprocessingService)
{
    public async Task<List<UploadedDocument>?> ExecuteAsync(
        Guid dealId, IReadOnlyList<UploadedFile> files, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var results = new List<UploadedDocument>();

        foreach (var file in files)
        {
            var documentId = Guid.NewGuid();
            var storagePath = await fileStorage.SaveAsync(dealId, documentId, file.FileName, file.Bytes, cancellationToken);

            var document = new UploadedDocument
            {
                Id = documentId,
                DealId = dealId,
                FileName = file.FileName,
                ContentType = file.ContentType,
                StoragePath = storagePath,
                UploadedAt = DateTime.UtcNow,
            };
            await documentRepository.AddAsync(document, cancellationToken);

            try
            {
                var analysis = await analysisService.AnalyzeAsync(file.Bytes, file.ContentType, cancellationToken);
                document.DocumentType = analysis.Type;
                document.TypeConfidence = analysis.TypeConfidence;
                document.OcrText = analysis.OcrText;
                document.ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(analysis.Fields);
                document.Status = DocumentProcessingStatus.Processed;
            }
            catch (Exception ex)
            {
                document.Status = DocumentProcessingStatus.Failed;
                document.ErrorMessage = ex.Message;
            }

            document.ProcessedAt = DateTime.UtcNow;
            await documentRepository.UpdateAsync(document, cancellationToken);
            results.Add(document);
        }

        await preprocessingService.RefreshAsync(dealId, cancellationToken);
        return results;
    }
}
