using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class QuestionDeduplicationTests
{
    [Fact]
    public async Task Same_unanswered_field_group_is_not_reworded_across_turns()
    {
        var fields = RequiredFields((1, "мерос рақами"));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":"Подскажите номер наследственного дела?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);
        var askedQuestions = new Dictionary<string, string>();

        var first = await planner.ExecuteAsync(
            "Inheritance", "ru", null, "some message", DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);

        Assert.Equal(1, first.FieldId);
        Assert.Equal("Подскажите номер наследственного дела?", first.Question);
        Assert.True(askedQuestions.ContainsKey("1"));

        // Second turn: field is still unanswered. The generator would
        // return different wording if called again, but it must not be
        // called at all - the cached question is reused verbatim.
        var second = await planner.ExecuteAsync(
            "Inheritance", "ru", null, "Тестовый ответ", DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);

        Assert.Equal(1, second.FieldId);
        Assert.Contains("Подскажите номер наследственного дела?", second.Question);
        Assert.Contains(ConversationReplies.RepeatedQuestionNotice("ru"), second.Question);
        Assert.DoesNotContain("Уточните номер наследственного дела", second.Question);
    }

    [Fact]
    public async Task Repeat_notice_is_not_stacked_on_a_third_ask()
    {
        var fields = RequiredFields((1, "мерос рақами"));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":"Подскажите номер наследственного дела?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);
        var askedQuestions = new Dictionary<string, string>();

        await planner.ExecuteAsync(
            "Inheritance", "ru", null, "some message", DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);
        var second = await planner.ExecuteAsync(
            "Inheritance", "ru", null, "Тестовый ответ", DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);
        var third = await planner.ExecuteAsync(
            "Inheritance", "ru", null, "Ещё один тестовый ответ", DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);

        Assert.Equal(second.Question, third.Question);
        var noticeCount = CountOccurrences(third.Question!, ConversationReplies.RepeatedQuestionNotice("ru"));
        Assert.Equal(1, noticeCount);
    }

    [Fact]
    public async Task Different_field_group_still_gets_a_freshly_generated_question()
    {
        var fields = RequiredFields((1, "мерос рақами"), (2, "васиятнома санаси"));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":"Подскажите номер наследственного дела?","extracted":{"1":"12345"}}""",
            """{"question":"Когда была составлена справка?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);
        var askedQuestions = new Dictionary<string, string>();

        var first = await planner.ExecuteAsync(
            "Inheritance", "ru", null, null, DocumentFieldHintCollection.Empty,
            fields, Labels(fields), answers, askedQuestions, CancellationToken.None);

        Assert.Equal("12345", answers[1]);
        Assert.Equal(2, first.FieldId);
        Assert.Equal("Когда была составлена справка?", first.Question);
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
            1 => "мерос рақами",
            2 => "васиятнома санаси",
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
