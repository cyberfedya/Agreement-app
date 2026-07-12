using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Contracts.Documents;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Api.Endpoints;

public static class DocumentEndpoints
{
    private const string DefaultLanguage = "ru";

    public static IEndpointRouteBuilder MapDocumentEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/deals").WithTags("Documents");

        group.MapPost("/{id:guid}/documents", async (
            Guid id, HttpRequest request, UploadDocumentsUseCase useCase, CancellationToken ct) =>
        {
            if (!request.HasFormContentType)
                return UploadError("INVALID_MULTIPART_REQUEST", "Documents must be uploaded as multipart form data.");

            var form = await request.ReadFormAsync(ct);
            if (form.Files.Count == 0)
                return UploadError("DOCUMENTS_REQUIRED", "Upload at least one document.");

            var files = new List<UploadedFile>();
            foreach (var file in form.Files)
            {
                using var stream = new MemoryStream();
                await file.CopyToAsync(stream, ct);
                files.Add(new UploadedFile(file.FileName, file.ContentType, stream.ToArray()));
            }

            try
            {
                var results = await useCase.ExecuteAsync(id, files, request.Query["lang"].FirstOrDefault() ?? DefaultLanguage, ct);
                return results is null ? Results.NotFound() : Results.Ok(results.Select(ToDto));
            }
            catch (DocumentUploadValidationException ex)
            {
                return UploadError(ex.Validation.ErrorCode!, ex.Validation.Message!, ex.Validation.FileIndex);
            }
        })
        .WithName("UploadDocuments")
        .DisableAntiforgery();

        group.MapGet("/{id:guid}/documents", async (Guid id, GetDealDocumentsUseCase useCase, CancellationToken ct) =>
        {
            var documents = await useCase.ExecuteAsync(id, ct);
            return Results.Ok(documents.Select(ToDto));
        })
        .WithName("GetDealDocuments");

        group.MapGet("/{id:guid}/document-conflicts", async (
            Guid id, GetDealDocumentConflictsUseCase useCase, CancellationToken ct) =>
        {
            var conflicts = await useCase.ExecuteAsync(id, ct);
            return conflicts is null
                ? Results.NotFound()
                : Results.Ok(conflicts.Select(conflict => new DocumentConflictDto(
                    conflict.Type,
                    conflict.Field,
                    conflict.Severity,
                    conflict.Reason,
                    conflict.RecommendedResolution,
                    conflict.Values.Select(value => new DocumentConflictValueDto(
                        value.DocumentId, value.FileName, value.Value, value.Confidence, value.Source)).ToList())));
        })
        .WithName("GetDealDocumentConflicts");

        group.MapGet("/{id:guid}/required-documents", async (
            Guid id, string? lang, GetRequiredDocumentsUseCase useCase, CancellationToken ct) =>
        {
            var required = await useCase.ExecuteAsync(id, lang ?? DefaultLanguage, ct);
            if (required is null)
                return Results.NotFound();

            return Results.Ok(required.Select(r =>
                new RequiredDocumentDto(r.Type.ToString(), r.Title, r.Description, r.Required, r.Priority)));
        })
        .WithName("GetRequiredDocuments");

        group.MapDelete("/{id:guid}/documents/{documentId:guid}", async (
            Guid id, Guid documentId, DeleteDocumentUseCase useCase, CancellationToken ct) =>
        {
            var deleted = await useCase.ExecuteAsync(id, documentId, ct);
            return deleted ? Results.NoContent() : Results.NotFound();
        })
        .WithName("DeleteDocument");

        group.MapPatch("/{id:guid}/documents/{documentId:guid}/fields", async (
            Guid id, Guid documentId, UpdateDocumentFieldRequest request, UpdateDocumentFieldUseCase useCase, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.Key))
                return Results.BadRequest();

            var updated = await useCase.ExecuteAsync(id, documentId, request.Key, request.Value, ct);
            return updated ? Results.NoContent() : Results.NotFound();
        })
        .WithName("UpdateDocumentField");

        group.MapGet("/{id:guid}/interview-preview", async (
            Guid id, string? lang, GetInterviewPreviewUseCase useCase, CancellationToken ct) =>
        {
            var preview = await useCase.ExecuteAsync(id, lang ?? DefaultLanguage, ct);
            return preview is null
                ? Results.NotFound()
                : Results.Ok(new InterviewPreviewDto(preview.TotalAskableFields, preview.EstimatedRemainingQuestions));
        })
        .WithName("GetInterviewPreview");

        return app;
    }

    private static UploadedDocumentDto ToDto(UploadedDocument document)
    {
        var fields = ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson)
            .ToDictionary(kv => kv.Key, kv => new ExtractedFieldDto(kv.Value.Value, kv.Value.Confidence));
        foreach (var (key, field) in NormalizedDocumentFieldsSerializer.Deserialize(document.NormalizedFieldsJson))
            fields[key] = new ExtractedFieldDto(field.Value, field.Confidence);

        return new UploadedDocumentDto(
            document.Id,
            document.FileName,
            document.DocumentType.ToString(),
            document.TypeConfidence,
            document.Status.ToString(),
            document.ErrorMessage,
            document.MismatchWarning,
            fields);
    }

    private static IResult UploadError(string errorCode, string message, int? fileIndex = null) =>
        Results.BadRequest(new
        {
            errorCode,
            message,
            details = fileIndex is null ? null : new { fileIndex },
        });
}
