using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class DocumentVerificationEngineTests
{
    private static AgreementTemplateField Field(int id) => new() { FieldId = id, Mode = AgreementFieldMode.Required };

    [Fact]
    public void Conflicting_answer_and_document_value_becomes_a_conflict()
    {
        var fields = new[] { Field(23) };
        var labels = new Dictionary<int, string> { [23] = "Автотранспортнинг двигатель рақами" };
        var answers = new Dictionary<int, string> { [23] = "AB1234" };
        var hints = new DocumentFieldHintCollection([new DocumentFieldHint("engine_number", "CD5678", 0.9, "document")]);

        var outcome = DocumentVerificationEngine.Evaluate(fields, labels, answers, hints);

        var conflict = Assert.Single(outcome.Conflicts);
        Assert.Equal(23, conflict.FieldId);
        Assert.Equal("AB1234", conflict.UserValue);
        Assert.Equal("CD5678", conflict.DocumentValue);
        Assert.Empty(outcome.AutoFilled);
    }

    [Fact]
    public void Matching_answer_and_document_value_is_not_a_conflict()
    {
        var fields = new[] { Field(23) };
        var labels = new Dictionary<int, string> { [23] = "Автотранспортнинг двигатель рақами" };
        var answers = new Dictionary<int, string> { [23] = "  AB1234  " };
        var hints = new DocumentFieldHintCollection([new DocumentFieldHint("engine_number", "ab1234", 0.9, "document")]);

        var outcome = DocumentVerificationEngine.Evaluate(fields, labels, answers, hints);

        Assert.Empty(outcome.Conflicts);
        Assert.Empty(outcome.AutoFilled);
    }

    [Fact]
    public void Document_value_for_a_field_the_user_never_answered_is_silently_auto_filled()
    {
        var fields = new[] { Field(25) };
        var labels = new Dictionary<int, string> { [25] = "Автотранспортнинг шасси рақами" };
        var answers = new Dictionary<int, string>();
        var hints = new DocumentFieldHintCollection([new DocumentFieldHint("chassis_number", "EF9012", 0.9, "document")]);

        var outcome = DocumentVerificationEngine.Evaluate(fields, labels, answers, hints);

        Assert.Empty(outcome.Conflicts);
        Assert.Equal("EF9012", outcome.AutoFilled[25]);
    }

    [Fact]
    public void Implausible_document_value_is_not_silently_auto_filled()
    {
        var fields = new[] { Field(30) };
        var labels = new Dictionary<int, string>
        {
            [30] = "Автотранспорт воситасига қайд этиш гувоҳномаси берилган сана",
        };
        var answers = new Dictionary<int, string>();
        // "issue_date" clears DocumentFieldMapper's confidence bar but the
        // value has no digit and isn't a recognizable relative date - the
        // same shape check InterviewPlanner applies to every other
        // document-derived value must reject it here too, since this path
        // writes to answers with no user confirmation at all.
        var hints = new DocumentFieldHintCollection([new DocumentFieldHint("issue_date", "не дата", 0.9, "document")]);

        var outcome = DocumentVerificationEngine.Evaluate(fields, labels, answers, hints);

        Assert.Empty(outcome.Conflicts);
        Assert.Empty(outcome.AutoFilled);
    }

    [Fact]
    public void No_document_hints_produces_no_conflicts_and_no_auto_fill()
    {
        var fields = new[] { Field(23), Field(24) };
        var labels = new Dictionary<int, string>
        {
            [23] = "Автотранспортнинг двигатель рақами",
            [24] = "Автотранспортнинг кузов рақами",
        };
        var answers = new Dictionary<int, string> { [23] = "AB1234" };
        var hints = new DocumentFieldHintCollection([]);

        var outcome = DocumentVerificationEngine.Evaluate(fields, labels, answers, hints);

        Assert.Empty(outcome.Conflicts);
        Assert.Empty(outcome.AutoFilled);
    }
}
