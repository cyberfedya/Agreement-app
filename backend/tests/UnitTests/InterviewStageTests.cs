using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class InterviewStageTests
{
    [Fact]
    public void Vehicle_identifier_cluster_is_grouped_into_one_question()
    {
        var fields = new[]
        {
            new ClassifiedField(21, "Автотранспорт русуми", FieldCategory.RequiredObject),
            new ClassifiedField(22, "Автотранспорт воситаси ишлаб чиқарилган йил", FieldCategory.RequiredObject),
            new ClassifiedField(37, "Автотранспорт воситасининг VIN рақами", FieldCategory.RequiredObject),
            new ClassifiedField(23, "Автотранспортнинг двигатель рақами", FieldCategory.RequiredObject),
            new ClassifiedField(24, "Автотранспортнинг кузов рақами", FieldCategory.RequiredObject),
            new ClassifiedField(25, "Автотранспортнинг шасси рақами", FieldCategory.RequiredObject),
            new ClassifiedField(33, "Автотранспорт воситасининг ранги", FieldCategory.RequiredObject),
        };

        var ordered = QuestionPriorityEngine.Order(fields);

        // The cluster (VIN/engine/kuzov/chassis) sorts as one adjacent
        // block right after brand/year, before anything else - regardless
        // of VIN's much higher FieldId.
        Assert.Equal([21, 22, 23, 24, 25, 37, 33], ordered.Select(f => f.FieldId).ToArray());

        var groups = QuestionGroupingEngine.BuildGroups(ordered);

        // "Марка и модель" (21) and "год выпуска" (22) are their own
        // documented cluster (vehicle_identity) - see FieldClusterCatalog -
        // since there's no separate "модель" field to split them into.
        Assert.Equal(3, groups.Count);
        Assert.Equal([21, 22], groups[0].Select(f => f.FieldId).ToArray());
        Assert.Equal([23, 24, 25, 37], groups[1].Select(f => f.FieldId).ToArray());
        Assert.Equal([33], groups[2].Select(f => f.FieldId).ToArray());
    }

    [Fact]
    public void Non_cluster_fields_of_the_same_category_still_stay_one_topic_per_question()
    {
        // Color and "known defects" are both plain RequiredObject fields
        // with no FieldClusterCatalog entry - being the same category
        // alone must not merge them (MaxGroupSize = 1 for the generic
        // fallback), unlike 21/22 above which are clustered on purpose.
        var fields = new[]
        {
            new ClassifiedField(33, "Автотранспорт воситасининг ранги", FieldCategory.RequiredObject),
            new ClassifiedField(38, "Автотранспорт воситасининг маълум носозликлари ёки хусусиятлари", FieldCategory.RequiredObject),
        };

        var groups = QuestionGroupingEngine.BuildGroups(QuestionPriorityEngine.Order(fields));

        Assert.Equal(2, groups.Count);
        Assert.All(groups, g => Assert.Single(g));
    }

    [Theory]
    [InlineData("ru", "🚗", "Автомобиль")]
    [InlineData("en", "🚗", "Vehicle")]
    public void Vehicle_object_stage_resolves_localized_icon_and_label(string language, string icon, string label)
    {
        var stage = InterviewStageCatalog.Resolve("vehicle", FieldCategory.RequiredObject, language);

        Assert.NotNull(stage);
        Assert.Equal("object", stage!.Key);
        Assert.Equal(icon, stage.Icon);
        Assert.Equal(label, stage.Label);
    }

    [Fact]
    public void Vehicle_time_and_commercial_fields_resolve_to_the_terms_stage()
    {
        var timeStage = InterviewStageCatalog.Resolve("vehicle", FieldCategory.RequiredTime, "ru");
        var commercialStage = InterviewStageCatalog.Resolve("vehicle", FieldCategory.RequiredCommercial, "ru");

        Assert.Equal("terms", timeStage!.Key);
        Assert.Equal("Условия сделки", timeStage.Label);
        Assert.Equal("terms", commercialStage!.Key);
        Assert.Equal("Условия сделки", commercialStage.Label);
    }

    [Fact]
    public void Loan_domain_gets_its_own_terms_label_instead_of_the_generic_one()
    {
        var stage = InterviewStageCatalog.Resolve("loan", FieldCategory.RequiredCommercial, "ru");

        Assert.Equal("Условия возврата", stage!.Label);
    }

    [Fact]
    public void Unknown_domain_falls_back_to_a_generic_stage_pair()
    {
        var objectStage = InterviewStageCatalog.Resolve("court", FieldCategory.RequiredObject, "ru");
        var termsStage = InterviewStageCatalog.Resolve("court", FieldCategory.RequiredCommercial, "ru");

        Assert.Equal("Предмет договора", objectStage!.Label);
        Assert.Equal("Условия договора", termsStage!.Label);
    }

    [Theory]
    [InlineData(FieldCategory.NeverAsk)]
    [InlineData(FieldCategory.DocumentOnly)]
    [InlineData(FieldCategory.Optional)]
    public void Fields_that_are_never_the_current_question_have_no_stage(FieldCategory category)
    {
        Assert.Null(InterviewStageCatalog.Resolve("vehicle", category, "ru"));
    }
}
