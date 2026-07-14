using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class AnswerShapeValidationTests
{
    [Theory]
    [InlineData("нарх", "Тестовый ответ", false)]
    [InlineData("нарх", "15 000 000 сум", true)]
    [InlineData("тўлов сана", "Тестовый ответ", false)]
    [InlineData("тўлов сана", "15.08.2026", true)]
    [InlineData("муддат", "бессрочно", true)]
    [InlineData("объект номи", "Тестовый ответ", true)]
    public void LooksPlausible_checks_digits_for_money_and_date_labels(string label, string answer, bool expected)
    {
        Assert.Equal(expected, AnswerShapeValidator.LooksPlausible(label, answer));
    }

    /// <summary>
    /// Payment-METHOD answers legitimately contain no digits at all - the
    /// label shares money vocabulary ("тўлов") with amount fields, and the
    /// digit requirement used to reject every valid answer here, re-asking
    /// the same question in a guaranteed loop.
    /// </summary>
    [Theory]
    [InlineData("Тўлов қандай амалга оширилади", "Наличными")]
    [InlineData("Тўлов қандай амалга оширилади", "Банковским переводом")]
    [InlineData("Тўлов қандай амалга оширилади", "Рассрочка")]
    [InlineData("Способ оплаты", "наличными")]
    public void Payment_method_answers_without_digits_are_plausible(string label, string answer)
    {
        Assert.True(AnswerShapeValidator.LooksPlausible(label, answer));
    }

    /// <summary>Common digit-free but perfectly concrete date answers.</summary>
    [Theory]
    [InlineData("Автотранспорт воситасини топшириш санаси", "через неделю")]
    [InlineData("Автотранспорт воситасини топшириш санаси", "при подписании договора")]
    [InlineData("топшириш санаси", "бир хафтадан кейин")]
    public void Relative_date_answers_are_plausible(string label, string answer)
    {
        Assert.True(AnswerShapeValidator.LooksPlausible(label, answer));
    }

    [Fact]
    public async Task Implausible_direct_answer_is_not_recorded_and_asks_for_clarification()
    {
        var manager = new ConversationManager(
            new IntentClassifier(new StaticChatClient("ANSWER")),
            new SideQuestionAnswerer(new StaticChatClient("n/a")),
            new InterviewPlanner(new QuestionGenerator(new StaticChatClient("n/a"))));

        var fields = RequiredFields((1, "сумма"));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await manager.ExecuteAsync(
            "loan",
            "Loan agreement",
            "ru",
            null,
            DocumentFieldHintCollection.Empty,
            1,
            "Тестовый ответ",
            "Какая сумма займа?",
            fields,
            Labels(fields),
            answers,
            new Dictionary<string, string>(),
            new HashSet<string>(),
            CancellationToken.None);

        Assert.Equal(1, result.FieldId);
        Assert.False(answers.ContainsKey(1));
        Assert.Contains("Какая сумма займа?", result.Question);
    }

    [Fact]
    public async Task Repeated_implausible_answers_do_not_stack_the_clarification_notice()
    {
        var manager = new ConversationManager(
            new IntentClassifier(new StaticChatClient("ANSWER")),
            new SideQuestionAnswerer(new StaticChatClient("n/a")),
            new InterviewPlanner(new QuestionGenerator(new StaticChatClient("n/a"))));

        var fields = RequiredFields((1, "сумма"));
        var answers = DealAnswersSerializer.Deserialize(null);

        var first = await manager.ExecuteAsync(
            "loan", "Loan agreement", "ru", null, DocumentFieldHintCollection.Empty,
            1, "Тестовый ответ", "Какая сумма займа?",
            fields, Labels(fields), answers, new Dictionary<string, string>(), new HashSet<string>(), CancellationToken.None);

        // The client echoes back exactly what it was just shown - which is
        // already notice-wrapped from the first mismatch.
        var second = await manager.ExecuteAsync(
            "loan", "Loan agreement", "ru", null, DocumentFieldHintCollection.Empty,
            1, "Ещё один нерелевантный ответ", first.Question!,
            fields, Labels(fields), answers, new Dictionary<string, string>(), new HashSet<string>(), CancellationToken.None);

        Assert.Equal(first.Question, second.Question);
        var noticeCount = CountOccurrences(second.Question!, "Уточните, пожалуйста:");
        Assert.Equal(1, noticeCount);
    }

    private static int CountOccurrences(string text, string substring)
    {
        var count = 0;
        var index = 0;
        while ((index = text.IndexOf(substring, index, StringComparison.Ordinal)) != -1)
        {
            count++;
            index += substring.Length;
        }

        return count;
    }

    [Fact]
    public async Task Plausible_direct_answer_is_recorded_and_interview_advances()
    {
        var fields = RequiredFields((1, "сумма"), (2, "объект"));
        var manager = new ConversationManager(
            new IntentClassifier(new StaticChatClient("ANSWER")),
            new SideQuestionAnswerer(new StaticChatClient("n/a")),
            new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
                """{"question":"What is the object?","extracted":{}}"""))));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await manager.ExecuteAsync(
            "loan",
            "Loan agreement",
            "ru",
            null,
            DocumentFieldHintCollection.Empty,
            1,
            "15 000 000 сум",
            "Какая сумма займа?",
            fields,
            Labels(fields),
            answers,
            new Dictionary<string, string>(),
            new HashSet<string>(),
            CancellationToken.None);

        Assert.Equal("15 000 000 сум", answers[1]);
        Assert.Equal(2, result.FieldId);
    }

    private static IReadOnlyList<AgreementTemplateField> RequiredFields(params (int Id, string Label)[] fields) =>
        fields.Select(field => new AgreementTemplateField
        {
            Id = Guid.NewGuid(),
            AgreementTemplateId = Guid.NewGuid(),
            FieldId = field.Id,
            Mode = AgreementFieldMode.Required,
        }).ToList();

    private static IReadOnlyDictionary<int, string> Labels(IEnumerable<AgreementTemplateField> fields) =>
        fields.ToDictionary(f => f.FieldId, f => f.FieldId switch
        {
            1 => "сумма",
            2 => "объект",
            _ => f.FieldId.ToString(),
        });

    private sealed class StaticChatClient(params string[] responses) : IAiChatClient
    {
        private int _index;

        public Task<string> CompleteAsync(
            string systemPrompt,
            string userMessage,
            CancellationToken cancellationToken = default)
        {
            var response = responses[Math.Min(_index, responses.Length - 1)];
            _index++;
            return Task.FromResult(response);
        }
    }
}
