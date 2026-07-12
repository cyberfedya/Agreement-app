using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Contracts.Deals;
using EasyAgree.Contracts.Templates;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Validation;
using EasyAgree.Application.Risk;

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

            if (result.IsSuggestDocument)
            {
                var docType = result.SuggestedDocumentType!.Value;
                var suggestion = new DocumentSuggestionDto(
                    docType.ToString(),
                    DocumentSuggestionReplies.Title(docType, lang ?? DefaultLanguage),
                    DocumentSuggestionReplies.Description(docType, lang ?? DefaultLanguage),
                    result.SuggestedMatchedFieldCount);
                return Results.Ok(new NextQuestionResponse("suggest_document", null, null, [], suggestion));
            }

            var status = result.IsReadyToGenerate ? "ready_to_generate" : "need_more_info";
            List<int> missing = result.NextFieldId is { } fieldId ? [fieldId] : [];
            return Results.Ok(new NextQuestionResponse(status, result.NextFieldId, result.NextQuestion, missing));
        })
        .WithName("GetNextQuestion");

        group.MapPost("/{id:guid}/document-suggestions/dismiss", async (
            Guid id, DismissDocumentSuggestionRequest request, DismissDocumentSuggestionUseCase useCase, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.DocumentType))
                return Results.BadRequest();

            var success = await useCase.ExecuteAsync(id, request.DocumentType, ct);
            return success ? Results.NoContent() : Results.NotFound();
        })
        .WithName("DismissDocumentSuggestion");

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

        group.MapGet("/{id:guid}/review", async (Guid id, GetDealReviewUseCase useCase, CancellationToken ct) =>
        {
            var review = await useCase.ExecuteAsync(id, ct);
            return review is null
                ? Results.NotFound()
                : Results.Ok(new DealReviewDto(
                    review.AutoFilled.Select(ToReviewField).ToList(),
                    review.Manual.Select(ToReviewField).ToList(),
                    review.Corrected.Select(ToReviewField).ToList(),
                    review.Missing.Select(ToReviewField).ToList(),
                    review.Skipped.Select(ToReviewField).ToList()));
        })
        .WithName("GetDealReview");

        group.MapGet("/{id:guid}/quality", async (Guid id, GetDealQualityUseCase useCase, CancellationToken ct) =>
        {
            var quality = await useCase.ExecuteAsync(id, ct);
            return quality is null
                ? Results.NotFound()
                : Results.Ok(new AgreementQualityDto(
                    quality.Score,
                    quality.RequiredCompletion,
                    quality.AutomaticCompletion,
                    quality.ManualCompletion,
                    quality.Consistency,
                    quality.DocumentConfidence,
                    quality.Recommendations.Select(recommendation =>
                        new QualityRecommendationDto(recommendation.Code, recommendation.Message, recommendation.Importance)).ToList()));
        })
        .WithName("GetDealQuality");

        group.MapGet("/{id:guid}/validation", async (Guid id, GetDealAgreementValidationUseCase useCase, CancellationToken ct) =>
        {
            var validation = await useCase.ExecuteAsync(id, ct);
            return validation is null
                ? Results.NotFound()
                : Results.Ok(new AgreementValidationDto(validation.IsValid,
                    validation.Issues.Select(issue => new AgreementValidationIssueDto(
                        issue.Code, issue.Severity, issue.FieldId, issue.Label, issue.Message, issue.RecommendedAction)).ToList()));
        })
        .WithName("GetDealAgreementValidation");

        group.MapGet("/{id:guid}/risk", async (Guid id, GetDealRiskAssessmentUseCase useCase, CancellationToken ct) =>
        {
            var risk = await useCase.ExecuteAsync(id, ct);
            return risk is null
                ? Results.NotFound()
                : Results.Ok(new AgreementRiskDto(
                    risk.OverallRisk, risk.RiskLevel, risk.Confidence, risk.Summary,
                    risk.Categories.Select(category => new RiskCategoryDto(category.Name, category.Risk, category.Reason)).ToList(),
                    risk.Issues.Select(issue => new AgreementRiskIssueDto(
                        issue.Code, issue.Severity, issue.Field, issue.Title, issue.Description,
                        issue.RecommendedAction, issue.CanAutoFix)).ToList(),
                    risk.Recommendations.Select(recommendation => new AgreementRiskRecommendationDto(
                        recommendation.IssueCode, recommendation.Message, recommendation.Importance)).ToList()));
        })
        .WithName("GetDealRiskAssessment");

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
                AcceptInviteOutcome.Accepted => Results.Ok(new { success = true }),
                AcceptInviteOutcome.DealNotFound => Results.NotFound(),
                AcceptInviteOutcome.AlreadyResponded => Results.Conflict(new { error = "already_responded" }),
                AcceptInviteOutcome.OwnInvite => Results.Conflict(new { error = "own_invite" }),
                AcceptInviteOutcome.Expired => Results.Json(new { error = "expired" }, statusCode: StatusCodes.Status410Gone),
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

    private static DealReviewFieldDto ToReviewField(DealReviewField field) =>
        new(field.FieldId, field.Label, field.Value, field.Source, field.Confidence, field.Status, field.Reason);
}
