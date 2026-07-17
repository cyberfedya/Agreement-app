using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The architectural rule: a simple agreement must never turn into an
/// interrogation - the interview asks at most a per-domain maximum of
/// distinct questions before declaring itself ready, no matter how many
/// fields a template declares required. One number doesn't fit every
/// domain (a construction contract legitimately needs more terms than a
/// vehicle sale), so the cap is looked up by template domain. Fields left
/// unanswered past the cap render as a blank placeholder at generation
/// time (same as <see cref="FieldCategory.DocumentOnly"/> fields already
/// do) rather than blocking the interview.
/// </summary>
public sealed class InterviewQuestionCapTests
{
    /// <summary>Fifteen unrelated required fields - deliberately not grouping
    /// into topics, so each is its own question, to stress the cap.</summary>
    private static readonly List<AgreementTemplateField> Fields =
        Enumerable.Range(1, 15).Select(id => new AgreementTemplateField { FieldId = id, Mode = AgreementFieldMode.Required }).ToList();

    private static readonly Dictionary<int, string> Labels =
        Fields.ToDictionary(f => f.FieldId, f => $"unrelated condition number {f.FieldId}");

    private sealed class StaticQuestionAiClient : IAiChatClient
    {
        public Task<string> CompleteAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default) =>
            Task.FromResult("""{"question":"What is it?"}""");
    }

    /// <summary>Runs the fifteen-unrelated-fields interview to completion
    /// for the given domain, returning how many distinct questions were
    /// actually asked.</summary>
    private static async Task<int> RunToCompletion(string templateDomain)
    {
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticQuestionAiClient()));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();
        var questionsAsked = 0;
        string? currentMessage = null;

        for (var turn = 0; turn < 30; turn++)
        {
            var result = await planner.ExecuteAsync(
                templateDomain: templateDomain,
                templateTitle: "Test agreement",
                language: "ru",
                userRequest: null,
                currentMessage: currentMessage,
                documentHints: new DocumentFieldHintCollection([]),
                fields: Fields,
                labels: Labels,
                answers: answers,
                askedQuestions: askedQuestions,
                dismissedDocumentSuggestions: new HashSet<string>(),
                deferredFieldIds: new HashSet<int>(),
                cancellationToken: CancellationToken.None);

            if (result.IsReady)
                break;

            Assert.False(result.IsSuggestDocument);
            questionsAsked++;

            answers[result.FieldId!.Value] = "some answer";
            currentMessage = "some answer";
        }

        return questionsAsked;
    }

    [Fact]
    public async Task Vehicle_domain_caps_at_ten_questions()
    {
        // 10 = the full manual worst case: brand/model, year, engine
        // number, body number, plate, color, transfer date, payment
        // method, installment payoff date, price.
        var questionsAsked = await RunToCompletion("vehicle");
        Assert.True(questionsAsked <= 10, $"Vehicle interview asked {questionsAsked} questions - must never exceed 10.");
        Assert.True(questionsAsked > 0);
    }

    [Fact]
    public async Task Construction_domain_allows_more_questions_than_vehicle()
    {
        var vehicleCount = await RunToCompletion("vehicle");
        var constructionCount = await RunToCompletion("construction");

        Assert.True(constructionCount <= 15, $"Construction interview asked {constructionCount} questions - must never exceed 15.");
        Assert.True(
            constructionCount > vehicleCount,
            "A construction contract has real 15-question headroom that a vehicle sale (capped at 10) doesn't - " +
            "the cap must actually vary by domain, not just exist.");
    }

    [Fact]
    public async Task Loan_domain_uses_its_own_tighter_cap()
    {
        var questionsAsked = await RunToCompletion("loan");
        Assert.True(questionsAsked <= 9, $"Loan interview asked {questionsAsked} questions - must never exceed 9.");
    }

    /// <summary>
    /// The real vehicle_sale_agreement.json askable field set (brand,
    /// year, engine number, body number, plate, price, color, transfer
    /// date, payment method, conditional installment date) must be asked
    /// one at a time, in the natural order - subject first, then dates,
    /// then payment method, price last - and never exceed the vehicle
    /// domain's 10-question cap.
    /// </summary>
    [Fact]
    public async Task Vehicle_sale_interview_asks_in_natural_order_and_never_exceeds_ten_questions()
    {
        var fields = new List<AgreementTemplateField>
        {
            new() { FieldId = 21, Mode = AgreementFieldMode.Required },
            new() { FieldId = 22, Mode = AgreementFieldMode.Required },
            new() { FieldId = 23, Mode = AgreementFieldMode.Required },
            new() { FieldId = 24, Mode = AgreementFieldMode.Required },
            new() { FieldId = 26, Mode = AgreementFieldMode.Required },
            new() { FieldId = 32, Mode = AgreementFieldMode.Required },
            new() { FieldId = 33, Mode = AgreementFieldMode.Required },
            new() { FieldId = 34, Mode = AgreementFieldMode.Required },
            new() { FieldId = 35, Mode = AgreementFieldMode.Required },
            new() { FieldId = 36, Mode = AgreementFieldMode.Required },
        };
        var labels = new Dictionary<int, string>
        {
            [21] = "Автотранспорт русуми",
            [22] = "Автотранспорт воситаси ишлаб чиқарилган йил",
            [23] = "Автотранспортнинг двигатель рақами",
            [24] = "Автотранспортнинг кузов рақами",
            [26] = "Автотранспорт воситасининг давлат рақам белгиси",
            [33] = "Автотранспорт воситасининг ранги",
            [34] = "Автотранспорт воситасини топшириш санаси",
            [35] = "Тўлов қандай амалга оширилади",
            [36] = "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана",
            [32] = "Тарафлар ўзаро келишувига асосан автотранспорт воситасининг қиймати",
        };

        var planner = new InterviewPlanner(new QuestionGenerator(new StaticQuestionAiClient()));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();
        var dismissedDocumentSuggestions = new HashSet<string>();
        var askedFieldOrder = new List<int>();
        string? currentMessage = null;

        for (var turn = 0; turn < 30; turn++)
        {
            var result = await planner.ExecuteAsync(
                templateDomain: "vehicle",
                templateTitle: "Автотранспорт воситасининг олди-сотди шартномаси",
                language: "ru",
                userRequest: null,
                currentMessage: currentMessage,
                documentHints: new DocumentFieldHintCollection([]),
                fields: fields,
                labels: labels,
                answers: answers,
                askedQuestions: askedQuestions,
                dismissedDocumentSuggestions: dismissedDocumentSuggestions,
                deferredFieldIds: new HashSet<int>(),
                cancellationToken: CancellationToken.None);

            if (result.IsReady)
                break;

            if (result.IsSuggestDocument)
            {
                // The interview offers to upload the registration
                // certificate instead of asking engine/kuzov one by one -
                // simulate the user skipping it, same as
                // DismissDocumentSuggestionUseCase, and keep going.
                dismissedDocumentSuggestions.Add(result.SuggestedDocumentType!.Value.ToString());
                continue;
            }

            askedFieldOrder.Add(result.FieldId!.Value);
            Assert.True(askedFieldOrder.Count <= 10, $"Vehicle sale interview asked a {askedFieldOrder.Count}th question - must never exceed 10.");

            answers[result.FieldId!.Value] = "рассрочка"; // worst case: keeps the conditional installment-date field eligible too
            currentMessage = "рассрочка";
        }

        // Subject first (brand, year, engine, kuzov, plate, color), then
        // transfer date, then payment method + installment date, price last.
        Assert.Equal(new[] { 21, 22, 23, 24, 26, 33, 34, 35, 36, 32 }, askedFieldOrder);
    }
}
