using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// A clustered question (e.g. vehicle_identity: make/model + year, asked
/// together as one combined question) can be answered partially - the user
/// says only the year. Reported live: after answering just the year, the
/// interview never came back to ask about the make/model at all, reading
/// as if the model was silently dropped.
/// </summary>
public sealed class PartialGroupAnswerTests
{
    private sealed class ScriptedAiClient : IAiChatClient
    {
        private readonly Queue<string> _responses;
        public ScriptedAiClient(params string[] responses) => _responses = new Queue<string>(responses);

        public Task<string> CompleteAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default) =>
            Task.FromResult(_responses.Dequeue());
    }

    [Fact]
    public async Task Answering_only_the_year_still_asks_a_fresh_targeted_question_for_the_model()
    {
        var fields = new List<AgreementTemplateField>
        {
            new() { FieldId = 21, Mode = AgreementFieldMode.Required },
            new() { FieldId = 22, Mode = AgreementFieldMode.Required },
        };
        var labels = new Dictionary<int, string>
        {
            [21] = "Автотранспорт русуми",
            [22] = "Автотранспорт воситаси ишлаб чиқарилган йил",
        };

        // Turn 1: opening combined question. Turn 2: the model extracts the
        // year from "2020" and asks a fresh, specific follow-up for the
        // still-missing make/model - exactly what a real LLM does per the
        // "ask the shortest possible question for the missing field(s))"
        // instruction in QuestionGenerator's system prompt.
        var ai = new ScriptedAiClient(
            """{"question":"Какая марка, модель и год выпуска?"}""",
            """{"question":"Какая марка и модель?","extracted":{"22":"2020"}}""");
        var planner = new InterviewPlanner(new QuestionGenerator(ai));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();

        var first = await planner.ExecuteAsync(
            templateDomain: "vehicle",
            templateTitle: "Test agreement",
            language: "ru",
            userRequest: null,
            currentMessage: null,
            documentHints: new DocumentFieldHintCollection([]),
            fields: fields,
            labels: labels,
            answers: answers,
            askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: new HashSet<string>(),
            deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        Assert.Equal("Какая марка, модель и год выпуска?", first.Question);

        var second = await planner.ExecuteAsync(
            templateDomain: "vehicle",
            templateTitle: "Test agreement",
            language: "ru",
            userRequest: null,
            currentMessage: "2020",
            documentHints: new DocumentFieldHintCollection([]),
            fields: fields,
            labels: labels,
            answers: answers,
            askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: new HashSet<string>(),
            deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        // The year was extracted...
        Assert.Equal("2020", answers[22]);
        // ...and the interview must still be asking about the make/model
        // (fieldId 21), using the model's fresh targeted question - not the
        // stale "Ещё раз уточню: Какая марка, модель и год выпуска?" notice,
        // which would wrongly re-mention the year that's now already known.
        Assert.False(second.IsReady);
        Assert.Equal(21, second.FieldId);
        Assert.Equal("Какая марка и модель?", second.Question);
        Assert.DoesNotContain("Ещё раз уточню", second.Question);
    }
}
