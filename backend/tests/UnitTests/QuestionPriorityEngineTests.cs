using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class QuestionPriorityEngineTests
{
    /// <summary>
    /// A mortgage template's "what % of the home's value is the loan"
    /// field contains "қиймат" (value) - the same word the deal's actual
    /// price uses - but it is a ratio question, not the price itself, and
    /// must not be pushed to the very end of the interview alongside it.
    /// </summary>
    [Fact]
    public void Percentage_of_value_field_does_not_rank_as_the_final_price_question()
    {
        var fields = new List<ClassifiedField>
        {
            new(1, "Кредит суммаси", FieldCategory.RequiredCommercial),
            new(2, "Ипотека кредити суммаси уй-жой умумий қийматининг неча фоизини ташкил этиши", FieldCategory.RequiredCommercial),
            new(3, "Сотилаётган мулкнинг нархи", FieldCategory.RequiredCommercial),
        };

        var ordered = QuestionPriorityEngine.Order(fields).Select(f => f.FieldId).ToList();

        // The real price field (3) is the genuine final question; the
        // percentage-of-value field (2) sorts strictly before it, not
        // alongside it.
        Assert.Equal(3, ordered[^1]);
        Assert.True(ordered.IndexOf(2) < ordered.IndexOf(3));
    }
}
