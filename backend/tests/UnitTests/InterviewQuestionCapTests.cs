using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The architectural rule: a simple agreement must never turn into an
/// interrogation - the interview asks at most
/// <c>InterviewPlanner.MaxQuestionsPerInterview</c> distinct questions
/// before declaring itself ready, no matter how many fields a template
/// declares required. Fields left unanswered past the cap render as a
/// blank placeholder at generation time (same as
/// <see cref="FieldCategory.DocumentOnly"/> fields already do) rather than
/// blocking the interview.
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

    [Fact]
    public async Task Interview_never_asks_more_than_the_configured_maximum_of_questions()
    {
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticQuestionAiClient()));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();
        var questionsAsked = 0;
        string? currentMessage = null;

        for (var turn = 0; turn < 30; turn++)
        {
            var result = await planner.ExecuteAsync(
                templateDomain: "test",
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
                cancellationToken: CancellationToken.None);

            if (result.IsReady)
                break;

            Assert.False(result.IsSuggestDocument);
            questionsAsked++;
            Assert.True(questionsAsked <= 8, $"Interview asked a {questionsAsked}th question - must never exceed 8.");

            // Answer whatever field was just asked about and continue the
            // "conversation" so the planner moves to the next question.
            answers[result.FieldId!.Value] = "some answer";
            currentMessage = "some answer";
        }

        Assert.True(questionsAsked <= 8);
        Assert.True(questionsAsked > 0);
    }

    /// <summary>
    /// The real, expanded vehicle_sale_agreement.json field set (brand,
    /// year, engine/kuzov number, plate, VIN, color, special marks, price,
    /// transfer date, payment method, conditional installment date,
    /// additional conditions - 13 askable fields once notarial/identity
    /// fields are excluded) must still respect the 8-question cap end to
    /// end, exactly like the synthetic worst case above.
    /// </summary>
    [Fact]
    public async Task Vehicle_sale_agreement_interview_never_exceeds_eight_questions()
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
            new() { FieldId = 37, Mode = AgreementFieldMode.Required },
            new() { FieldId = 38, Mode = AgreementFieldMode.Required },
            new() { FieldId = 39, Mode = AgreementFieldMode.Required },
        };
        var labels = new Dictionary<int, string>
        {
            [21] = "Автотранспорт русуми",
            [22] = "Автотранспорт воситаси ишлаб чиқарилган йил",
            [23] = "Автотранспортнинг двигатель рақами",
            [24] = "Автотранспортнинг кузов рақами",
            [26] = "Автотранспорт воситасининг давлат рақам белгиси",
            [32] = "Тарафлар ўзаро келишувига асосан автотранспорт воситасининг қиймати",
            [33] = "Автотранспорт воситасининг VIN рақами",
            [34] = "Автотранспорт воситасининг ранги",
            [35] = "Автотранспорт воситасининг ажралиб турувчи белгилари",
            [36] = "Автотранспорт воситасини топшириш санаси",
            [37] = "Тўлов қандай амалга оширилади",
            [38] = "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана",
            [39] = "Битимнинг қўшимча шартлари",
        };

        var planner = new InterviewPlanner(new QuestionGenerator(new StaticQuestionAiClient()));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();
        var dismissedDocumentSuggestions = new HashSet<string>();
        var questionsAsked = 0;
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
                cancellationToken: CancellationToken.None);

            if (result.IsReady)
                break;

            if (result.IsSuggestDocument)
            {
                // The interview offers to upload the registration
                // certificate instead of asking VIN/engine/kuzov one by
                // one - simulate the user skipping it, same as
                // DismissDocumentSuggestionUseCase, and keep going.
                dismissedDocumentSuggestions.Add(result.SuggestedDocumentType!.Value.ToString());
                continue;
            }

            questionsAsked++;
            Assert.True(questionsAsked <= 8, $"Vehicle sale interview asked a {questionsAsked}th question - must never exceed 8.");

            answers[result.FieldId!.Value] = "рассрочка"; // worst case: keeps the conditional installment-date field eligible too
            currentMessage = "рассрочка";
        }

        Assert.True(questionsAsked <= 8);
    }
}
