using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class SmartInterviewPlannerTests
{
    [Fact]
    public void Groups_at_most_two_related_vehicle_fields_for_short_questions()
    {
        var fields = new List<ClassifiedField>
        {
            new(1, "vehicle VIN", FieldCategory.RequiredObject),
            new(2, "vehicle model", FieldCategory.RequiredObject),
            new(3, "vehicle plate", FieldCategory.RequiredObject),
            new(4, "property address", FieldCategory.RequiredObject),
        };

        var groups = QuestionGroupingEngine.BuildGroups(fields);

        Assert.Equal(new[] { 1, 2 }, groups[0].Select(field => field.FieldId));
        Assert.Equal(new[] { 3 }, groups[1].Select(field => field.FieldId));
        Assert.Equal(new[] { 4 }, groups[2].Select(field => field.FieldId));
    }

    [Fact]
    public void Cash_payment_makes_bank_details_obsolete()
    {
        var candidate = new ClassifiedField(2, "bank account", FieldCategory.RequiredCommercial);
        var labels = new Dictionary<int, string>
        {
            [1] = "payment method",
            [2] = "bank account",
        };
        var answers = new Dictionary<int, string> { [1] = "Cash" };

        Assert.True(FieldDependencyEngine.IsObsolete(candidate, answers, labels));
    }

    [Fact]
    public void Bank_details_remain_askable_for_non_cash_payment()
    {
        var candidate = new ClassifiedField(2, "bank account", FieldCategory.RequiredCommercial);
        var labels = new Dictionary<int, string>
        {
            [1] = "payment method",
            [2] = "bank account",
        };
        var answers = new Dictionary<int, string> { [1] = "Bank transfer" };

        Assert.False(FieldDependencyEngine.IsObsolete(candidate, answers, labels));
    }

    [Fact]
    public void Full_payment_date_is_obsolete_once_payment_method_is_known_and_is_not_installments()
    {
        var candidate = new ClassifiedField(38, "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана", FieldCategory.RequiredCommercial);
        var labels = new Dictionary<int, string>
        {
            [37] = "Тўлов қандай амалга оширилади",
            [38] = "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана",
        };
        var answers = new Dictionary<int, string> { [37] = "Нақд" };

        Assert.True(FieldDependencyEngine.IsObsolete(candidate, answers, labels));
    }

    [Fact]
    public void Full_payment_date_stays_askable_when_installments_were_chosen()
    {
        var candidate = new ClassifiedField(38, "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана", FieldCategory.RequiredCommercial);
        var labels = new Dictionary<int, string>
        {
            [37] = "Тўлов қандай амалга оширилади",
            [38] = "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана",
        };
        var answers = new Dictionary<int, string> { [37] = "Рассрочка" };

        Assert.False(FieldDependencyEngine.IsObsolete(candidate, answers, labels));
    }

    [Fact]
    public void Full_payment_date_stays_askable_before_payment_method_is_answered()
    {
        var candidate = new ClassifiedField(38, "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана", FieldCategory.RequiredCommercial);
        var labels = new Dictionary<int, string>
        {
            [37] = "Тўлов қандай амалга оширилади",
            [38] = "Бўлиб тўлаш ҳолатида тўлиқ тўлов амалга ошириладиган сана",
        };

        Assert.False(FieldDependencyEngine.IsObsolete(candidate, answers: new Dictionary<int, string>(), labels));
    }
}
