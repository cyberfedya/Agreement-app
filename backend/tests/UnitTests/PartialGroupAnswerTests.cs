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

    /// <summary>
    /// Reported live with a screenshot: answering "2020" got extracted into
    /// BOTH the make/model field AND the year field - the live document
    /// preview showed "Автотранспорт русуми: 2020" right next to
    /// "...ишлаб чиқарилган йил: 2020". The model imprecisely echoed the
    /// same value into both fieldIds of the combined group; only the year
    /// extraction should survive.
    /// </summary>
    [Fact]
    public async Task Same_value_extracted_for_both_group_fields_only_fills_the_field_it_actually_looks_plausible_for()
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

        var ai = new ScriptedAiClient(
            """{"question":"Какая марка, модель и год выпуска?"}""",
            // The imprecise extraction actually observed: both fieldIds
            // got the same bare year value.
            """{"question":null,"extracted":{"21":"2020","22":"2020"}}""");
        var planner = new InterviewPlanner(new QuestionGenerator(ai));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();

        await planner.ExecuteAsync(
            templateDomain: "vehicle", templateTitle: "Test agreement", language: "ru",
            userRequest: null, currentMessage: null, documentHints: new DocumentFieldHintCollection([]),
            fields: fields, labels: labels, answers: answers, askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: new HashSet<string>(), deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        var second = await planner.ExecuteAsync(
            templateDomain: "vehicle", templateTitle: "Test agreement", language: "ru",
            userRequest: null, currentMessage: "2020", documentHints: new DocumentFieldHintCollection([]),
            fields: fields, labels: labels, answers: answers, askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: new HashSet<string>(), deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        Assert.Equal("2020", answers[22]);
        Assert.False(answers.ContainsKey(21));
        Assert.Equal(21, second.FieldId);
    }

    /// <summary>
    /// The vehicle_identifiers cluster (VIN/engine/body/chassis, 4 fields)
    /// has no letters-vs-digits shape to distinguish a mis-attributed
    /// value the way AnswerShapeValidator's make/model check does - all
    /// four are arbitrary alphanumeric codes. If the model echoes the same
    /// code into two of them, neither can be trusted, so both must be
    /// rejected rather than silently keeping whichever happened first.
    /// </summary>
    [Fact]
    public async Task Same_code_echoed_into_two_technical_identifier_fields_fills_neither()
    {
        var fields = new List<AgreementTemplateField>
        {
            new() { FieldId = 37, Mode = AgreementFieldMode.Required },
            new() { FieldId = 23, Mode = AgreementFieldMode.Required },
            new() { FieldId = 24, Mode = AgreementFieldMode.Required },
            new() { FieldId = 25, Mode = AgreementFieldMode.Required },
        };
        var labels = new Dictionary<int, string>
        {
            [37] = "Автотранспорт воситасининг VIN рақами",
            [23] = "Автотранспортнинг двигатель рақами",
            [24] = "Автотранспортнинг кузов рақами",
            [25] = "Автотранспортнинг шасси рақами",
        };

        var ai = new ScriptedAiClient(
            """{"question":"Какой VIN, номер двигателя, кузова и шасси?"}""",
            // Engine and body wrongly got the same code as the VIN.
            """{"question":null,"extracted":{"37":"JT2SV22E8P0123456","23":"JT2SV22E8P0123456","24":"CD5678","25":"JT2SV22E8P0123456"}}""");
        var planner = new InterviewPlanner(new QuestionGenerator(ai));
        var answers = new Dictionary<int, string>();
        var askedQuestions = new Dictionary<string, string>();
        // These 4 fields also match the vehicle registration-certificate
        // document suggestion (>= MinMatchedFields=3) - dismiss it up front
        // so the planner actually reaches the question/extraction path
        // this test exercises, instead of short-circuiting to
        // SuggestDocument before ever calling the AI client.
        var dismissedDocumentSuggestions = new HashSet<string> { "VehicleRegistration" };

        await planner.ExecuteAsync(
            templateDomain: "vehicle", templateTitle: "Test agreement", language: "ru",
            userRequest: null, currentMessage: null, documentHints: new DocumentFieldHintCollection([]),
            fields: fields, labels: labels, answers: answers, askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: dismissedDocumentSuggestions, deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        await planner.ExecuteAsync(
            templateDomain: "vehicle", templateTitle: "Test agreement", language: "ru",
            userRequest: null, currentMessage: "VIN JT2SV22E8P0123456, кузов CD5678", documentHints: new DocumentFieldHintCollection([]),
            fields: fields, labels: labels, answers: answers, askedQuestions: askedQuestions,
            dismissedDocumentSuggestions: dismissedDocumentSuggestions, deferredFieldIds: new HashSet<int>(),
            cancellationToken: CancellationToken.None);

        // The duplicated code is shared by three fieldIds (37, 23, 25) - none
        // of them can be trusted, so none get filled. Only the genuinely
        // unique body number (24) is recorded.
        Assert.False(answers.ContainsKey(23));
        Assert.False(answers.ContainsKey(25));
        Assert.False(answers.ContainsKey(37));
        Assert.Equal("CD5678", answers[24]);
    }
}
