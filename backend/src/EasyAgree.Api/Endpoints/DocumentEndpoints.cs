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
                return Results.BadRequest();

            var form = await request.ReadFormAsync(ct);
            if (form.Files.Count == 0)
                return Results.BadRequest();

            var files = new List<UploadedFile>();
            foreach (var file in form.Files)
            {
                using var stream = new MemoryStream();
                await file.CopyToAsync(stream, ct);
                files.Add(new UploadedFile(file.FileName, file.ContentType, stream.ToArray()));
            }

            var results = await useCase.ExecuteAsync(id, files, ct);
            return results is null ? Results.NotFound() : Results.Ok(results.Select(ToDto));
        })
        .WithName("UploadDocuments")
        .DisableAntiforgery();

        group.MapGet("/{id:guid}/documents", async (Guid id, GetDealDocumentsUseCase useCase, CancellationToken ct) =>
        {
            var documents = await useCase.ExecuteAsync(id, ct);
            return Results.Ok(documents.Select(ToDto));
        })
        .WithName("GetDealDocuments");

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

        return new UploadedDocumentDto(
            document.Id,
            document.FileName,
            document.DocumentType.ToString(),
            document.TypeConfidence,
            document.Status.ToString(),
            document.ErrorMessage,
            fields);
    }
}
