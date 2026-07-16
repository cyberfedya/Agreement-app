using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class FieldClusterCatalogTests
{
    [Fact]
    public void Vehicle_identifiers_cluster_groups_all_four_fields()
    {
        var fields = new List<ClassifiedField>
        {
            new(37, "Автотранспорт воситасининг VIN рақами", FieldCategory.RequiredObject),
            new(23, "Автотранспортнинг двигатель рақами", FieldCategory.RequiredObject),
            new(24, "Автотранспортнинг кузов рақами", FieldCategory.RequiredObject),
            new(25, "Автотранспортнинг шасси рақами", FieldCategory.RequiredObject),
        };

        var groups = QuestionGroupingEngine.BuildGroups(fields);

        Assert.Single(groups);
        Assert.Equal(4, groups[0].Count);
        Assert.Equal(new[] { 37, 23, 24, 25 }, groups[0].Select(f => f.FieldId));
    }

    [Fact]
    public void Vehicle_identity_cluster_groups_make_model_and_year()
    {
        var fields = new List<ClassifiedField>
        {
            new(21, "Автотранспорт русуми", FieldCategory.RequiredObject),
            new(22, "Автотранспорт воситаси ишлаб чиқарилган йил", FieldCategory.RequiredObject),
        };

        var groups = QuestionGroupingEngine.BuildGroups(fields);

        Assert.Single(groups);
        Assert.Equal(2, groups[0].Count);
        Assert.Equal(new[] { 21, 22 }, groups[0].Select(f => f.FieldId));
    }

    [Fact]
    public void Ungrouped_field_yields_its_own_single_field_group()
    {
        var fields = new List<ClassifiedField> { new(5, "Тарафлар ўзаро келишувига асосан нархи", FieldCategory.RequiredCommercial) };

        var groups = QuestionGroupingEngine.BuildGroups(fields);

        Assert.Single(groups);
        Assert.Single(groups[0]);
        Assert.Equal(5, groups[0][0].FieldId);
    }

    [Fact]
    public void NeedMoreInfo_defaults_group_field_ids_to_just_the_one_field()
    {
        var result = InterviewPlanResult.NeedMoreInfo(7, "question text");

        Assert.Equal(new[] { 7 }, result.GroupFieldIds);
    }

    [Fact]
    public void NeedMoreInfo_carries_the_explicit_group_when_given_one()
    {
        var result = InterviewPlanResult.NeedMoreInfo(23, "question text", [23, 24, 25, 37]);

        Assert.Equal(new[] { 23, 24, 25, 37 }, result.GroupFieldIds);
    }
}
