using EasyAgree.Application.Deals;
using EasyAgree.Contracts.Deals;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Api.Endpoints;

public static class DealEndpoints
{
    private const string DefaultLanguage = "uz";

    public static IEndpointRouteBuilder MapDealEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/deals").WithTags("Deals");

        group.MapPost("/", async (
            CreateDealRequest request, CreateDealUseCase useCase, string? lang, CancellationToken ct) =>
        {
            var result = await useCase.ExecuteAsync(
                request.Text, request.TemplateKey, lang ?? DefaultLanguage, request.ProfileId, ct);
            return result.IsNoMatch ? Results.UnprocessableEntity(new { error = "no_match" }) : Results.Ok(result.Deal);
        })
        .WithName("CreateDeal");

        group.MapGet("/{id:guid}", async (Guid id, GetDealUseCase useCase, string? lang, CancellationToken ct) =>
        {
            var deal = await useCase.ExecuteAsync(id, lang ?? DefaultLanguage, ct);
            return deal is null ? Results.NotFound() : Results.Ok(deal);
        })
        .WithName("GetDeal");

        group.MapGet("/{id:guid}/questions", async (Guid id, GetDealQuestionsUseCase useCase, CancellationToken ct) =>
        {
            var questions = await useCase.ExecuteAsync(id, ct);
            return questions is null ? Results.NotFound() : Results.Ok(questions);
        })
        .WithName("GetDealQuestions");

        group.MapPost("/{id:guid}/next-question", async (
            Guid id, NextQuestionRequest request, GetNextQuestionUseCase useCase, string? lang, CancellationToken ct) =>
        {
            var result = await useCase.ExecuteAsync(id, request.FieldId, request.Answer, lang ?? DefaultLanguage, ct);

            if (result.IsNotFound)
                return Results.NotFound();

            var status = result.IsReadyToGenerate ? "ready_to_generate" : "need_more_info";
            List<int> missing = result.NextFieldId is { } fieldId ? [fieldId] : [];
            return Results.Ok(new NextQuestionResponse(status, result.NextFieldId, result.NextQuestion, missing));
        })
        .WithName("GetNextQuestion");

        group.MapPost("/{id:guid}/generate", async (
            Guid id, GenerateAgreementRequest request, GenerateFromDealUseCase useCase, CancellationToken ct) =>
        {
            var answers = request.Answers ?? [];
            var result = await useCase.ExecuteAsync(id, answers, ct);

            if (result.IsNotFound)
                return Results.NotFound();

            if (result.MissingFieldIds is { Count: > 0 })
                return Results.BadRequest(new GenerateAgreementErrorDto("missing_required_fields", result.MissingFieldIds));

            return Results.Ok(new GenerateAgreementResponse(id.ToString(), result.Html!, DateTime.UtcNow));
        })
        .WithName("GenerateFromDeal");

        return app;
    }
}
