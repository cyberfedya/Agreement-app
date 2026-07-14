using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class SmartInterviewPlannerTests
{
    [Fact]
    public void Every_field_is_its_own_question_group()
    {
        var fields = new List<ClassifiedField>
        {
            new(1, "vehicle VIN", FieldCategory.RequiredObject),
            new(2, "vehicle model", FieldCategory.RequiredObject),
            new(3, "vehicle plate", FieldCategory.RequiredObject),
            new(4, "property address", FieldCategory.RequiredObject),
        };

        var groups = QuestionGroupingEngine.BuildGroups(fields);

        Assert.Equal(4, groups.Count);
        Assert.All(groups, group => Assert.Single(group));
        Assert.Equal(new[] { 1, 2, 3, 4 }, groups.Select(group => group.Single().FieldId));
    }

    [Fact]
    public void Price_is_asked_last_after_object_dates_and_payment_method()
    {
        // The natural close of a negotiation: identify the car, settle
        // logistics and payment method, and only then name the price -
        // even though price (field 32) has a lower fieldId than the
        // payment fields.
        var fields = new List<ClassifiedField>
        {
            new(32, "Тарафлар ўзаро келишувига асосан автотранспорт воситасининг қиймати", FieldCategory.RequiredCommercial),
            new(35, "Тўлов қандай амалга оширилади", FieldCategory.RequiredCommercial),
            new(34, "Автотранспорт воситасини топшириш санаси", FieldCategory.RequiredTime),
            new(21, "Автотранспорт русуми", FieldCategory.RequiredObject),
        };

        var ordered = QuestionPriorityEngine.Order(fields);

        Assert.Equal(new[] { 21, 34, 35, 32 }, ordered.Select(field => field.FieldId));
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
