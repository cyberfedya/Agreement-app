using EasyAgree.Application.Templates;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Api.Endpoints;

public static class TemplateEndpoints
{
    private const string DefaultLanguage = "uz";

    public static IEndpointRouteBuilder MapTemplateEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/templates").WithTags("Templates");

        group.MapGet("/", async (GetTemplatesUseCase useCase, string? lang, CancellationToken ct) =>
        {
            var templates = await useCase.ExecuteAsync(lang ?? DefaultLanguage, ct);
            return Results.Ok(templates);
        })
        .WithName("GetTemplates");

        group.MapGet("/{key}", async (string key, GetTemplateUseCase useCase, string? lang, CancellationToken ct) =>
        {
            var template = await useCase.ExecuteAsync(key, lang ?? DefaultLanguage, ct);
            return template is null ? Results.NotFound() : Results.Ok(template);
        })
        .WithName("GetTemplate");

        group.MapGet("/{key}/questions", async (string key, GetQuestionsUseCase useCase, CancellationToken ct) =>
        {
            var questions = await useCase.ExecuteAsync(key, ct);
            return questions is null ? Results.NotFound() : Results.Ok(questions);
        })
        .WithName("GetTemplateQuestions");

        group.MapPost("/{key}/generate", async (
            string key, GenerateAgreementRequest request, GenerateAgreementUseCase useCase, CancellationToken ct) =>
        {
            var answers = request.Answers ?? [];
            var result = await useCase.ExecuteAsync(key, answers, ct);

            if (result.IsNotFound)
                return Results.NotFound();

            if (result.MissingFieldIds is { Count: > 0 })
                return Results.BadRequest(new GenerateAgreementErrorDto("missing_required_fields", result.MissingFieldIds));

            return Results.Ok(new GenerateAgreementResponse(key, result.Html!, DateTime.UtcNow));
        })
        .WithName("GenerateAgreement");

        return app;
    }
}
