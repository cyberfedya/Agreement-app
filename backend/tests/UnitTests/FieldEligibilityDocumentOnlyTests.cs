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

    /// <summary>
    /// Real labels pulled from agreements/vehicle/*.json (and the
    /// vehicle-pledge loan templates) that still slipped through as
    /// askable: the vehicle/trailer's own registration certificate
    /// ("гувоҳнома", also spelled "гувохнома" in several templates) -
    /// which department issued it, when, and its series/number - is
    /// printed on the physical document, never something an owner recalls
    /// unprompted, exactly like an engine or chassis number.
    /// </summary>
    [Theory]
    [InlineData("Автотранспорт воситасига қайд этиш гувоҳномаси берган ИИБ ЙХХБ номи")]
    [InlineData("Автотранспорт воситасига қайд этиш гувоҳномаси берган ТРИБ номи")]
    [InlineData("Автотранспорт воситасига қайд этиш гувоҳномаси берилган сана")]
    [InlineData("Автотранспорт воситасига берилган қайд этиш гувоҳномасининг серия ва рақами")]
    [InlineData("Автотранспорт гувоҳномаси қайд этган ҳудуд")]
    [InlineData("Автотранспорт гувоҳномаси қайд этилган сана")]
    [InlineData("Автотранспорт гувоҳномасига берилган серия рақами")]
    [InlineData("Автотранспортни қайд этган РИБ, ТРИБ")]
    [InlineData("Гувохномага берилган серия рақами")] // "гувохнома" spelling variant (no ҳ diacritic)
    [InlineData("Автотранспортнинг ким томонидан берилган")]
    [InlineData("Автотранспортнинг ким томонидан берилганлиги")]
    [InlineData("Автотранспортнинг берилган сана")]
    [InlineData("Автотранспорт берилган сана")]
    [InlineData("Автотранспорт воситасининг қайд этиш гувоҳномасига берилган серия рақами")]
    [InlineData("Автотранспорт воситасини қайд этиш гувоҳномасининг рақами")]
    [InlineData("Автотранспорт қайд этилган ҳудуд номи")]
    [InlineData("Автотранспорт воситаси қайд этилган ҳудуд")]
    public void Vehicle_registration_certificate_metadata_is_document_only(string label)
    {
        Assert.Equal(FieldCategory.DocumentOnly, Classify(label));
    }

    /// <summary>
    /// A near-identical phrase from an unrelated domain (trademark
    /// certificate number in a franchise agreement) must stay askable -
    /// the registration-certificate keywords are scoped to vehicle
    /// wording, not "any certificate has a number".
    /// </summary>
    [Fact]
    public void Non_vehicle_certificate_numbers_stay_askable()
    {
        // Contains "санаси" (date), so it's prioritized as a time field -
        // still genuinely askable, just not RequiredObject.
        Assert.Equal(
            FieldCategory.RequiredTime,
            Classify("Товар белгисининг номи гувоҳномасининг рақами, берилган санаси, амал қилиш муддати"));
    }
}
