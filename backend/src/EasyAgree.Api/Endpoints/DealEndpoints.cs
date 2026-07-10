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
            var result = await useCase.ExecuteAsync(
                id, request.FieldId, request.Answer, request.Question, lang ?? DefaultLanguage, ct);

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

        group.MapGet("/{id:guid}/agreement", async (Guid id, GetDealAgreementUseCase useCase, CancellationToken ct) =>
        {
            var result = await useCase.ExecuteAsync(id, ct);
            return result is null ? Results.NotFound() : Results.Ok(result);
        })
        .WithName("GetDealAgreement");

        group.MapGet("/{id:guid}/invite", async (Guid id, string? lang, GetDealInviteUseCase useCase, CancellationToken ct) =>
        {
            var result = await useCase.ExecuteAsync(id, lang, ct);
            if (result is null)
                return Results.NotFound();

            return Results.Ok(new DealInviteDto(
                result.DealId, result.TransactionType, result.FirstPartyRole, result.ExpectedSecondPartyRole,
                result.InvitedBy, result.InviteStatus, result.ExpiresAt));
        })
        .WithName("GetDealInvite");

        group.MapPost("/{id:guid}/invite/accept", async (
            Guid id, AcceptDealInviteRequest request, AcceptDealInviteUseCase useCase, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.ProfileId))
                return Results.BadRequest();

            var result = await useCase.ExecuteAsync(id, request.ProfileId, ct);
            return result.Outcome switch
            {
                AcceptInviteOutcome.Accepted => Results.NoContent(),
                AcceptInviteOutcome.DealNotFound => Results.NotFound(),
                AcceptInviteOutcome.AlreadyResponded => Results.Conflict(new { error = "already_responded" }),
                AcceptInviteOutcome.OwnInvite => Results.BadRequest(new { error = "own_invite" }),
                AcceptInviteOutcome.Expired => Results.BadRequest(new { error = "expired" }),
                _ => Results.Problem(),
            };
        })
        .WithName("AcceptDealInvite");

        group.MapPost("/{id:guid}/sign", async (
            Guid id, SignDealRequest request, SignDealSecondPartyUseCase useCase, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
                return Results.BadRequest();

            var success = await useCase.ExecuteAsync(id, request.FullName, ct);
            return success ? Results.NoContent() : Results.NotFound();
        })
        .WithName("SignDealSecondParty");

        return app;
    }
}
