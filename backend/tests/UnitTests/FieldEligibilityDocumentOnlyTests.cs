using EasyAgree.Application.Deals.Interview;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The minimal-interview rule for technical characteristics: fields an
/// ordinary owner does not know from memory are classified
/// <see cref="FieldCategory.DocumentOnly"/> - never asked, filled only
/// from uploaded documents - while the things owners genuinely know
/// (brand, model, year, plate, VIN, price, dates) stay askable.
/// </summary>
public sealed class FieldEligibilityDocumentOnlyTests
{
    private static FieldCategory Classify(string label, AgreementFieldMode mode = AgreementFieldMode.Required)
    {
        var fields = new[] { new AgreementTemplateField { FieldId = 1, Mode = mode } };
        var labels = new Dictionary<int, string> { [1] = label };
        return FieldEligibilityEngine.Classify(fields, labels).Single().Category;
    }

    [Theory]
    [InlineData("номер двигателя")]
    [InlineData("двигатель рақами")]
    [InlineData("мощность двигателя (л.с.)")]
    [InlineData("объем двигателя")]
    [InlineData("шасси рақами")]
    [InlineData("номер кузова")]
    [InlineData("снаряженная масса")]
    [InlineData("количество мест для сидения")]
    [InlineData("экологический класс")]
    [InlineData("вид топлива")]
    [InlineData("завод-изготовитель")]
    public void Technical_characteristics_are_document_only(string label)
    {
        Assert.Equal(FieldCategory.DocumentOnly, Classify(label));
    }

    [Theory]
    [InlineData("VIN рақами")]
    [InlineData("русуми (марка, модель)")]
    [InlineData("давлат рақам белгиси")]
    public void Vin_brand_model_and_plate_stay_askable_when_required(string label)
    {
        Assert.Equal(FieldCategory.RequiredObject, Classify(label));
    }

    [Fact]
    public void Price_and_transfer_date_stay_askable()
    {
        Assert.Equal(FieldCategory.RequiredCommercial, Classify("цена автомобиля"));
        Assert.Equal(FieldCategory.RequiredTime, Classify("топшириш санаси"));
    }

    [Fact]
    public void Technical_fields_are_document_only_even_when_the_template_marks_them_required()
    {
        Assert.Equal(FieldCategory.DocumentOnly, Classify("номер шасси", AgreementFieldMode.Required));
        Assert.Equal(FieldCategory.DocumentOnly, Classify("номер шасси", AgreementFieldMode.Optional));
    }
}
