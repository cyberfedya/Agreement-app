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
    [InlineData("мощность двигателя (л.с.)")]
    [InlineData("объем двигателя")]
    [InlineData("рама")]
    [InlineData("снаряженная масса")]
    [InlineData("количество мест для сидения")]
    [InlineData("экологический класс")]
    [InlineData("вид топлива")]
    [InlineData("завод-изготовитель")]
    public void Technical_characteristics_are_document_only(string label)
    {
        Assert.Equal(FieldCategory.DocumentOnly, Classify(label));
    }

    /// <summary>
    /// VIN, engine number, body/kuzov number and chassis number are askable
    /// - the owner can read them off the vehicle/documents, and the
    /// interview offers a photo-upload alternative alongside.
    /// QuestionGenerator's system prompt explicitly permits these four
    /// technical identifiers, so classification and the LLM instruction
    /// layer agree - a mismatch here previously made the model refuse to
    /// phrase the question and the interview looped on a vague fallback.
    /// </summary>
    [Theory]
    [InlineData("VIN рақами")]
    [InlineData("русуми (марка, модель)")]
    [InlineData("давлат рақам белгиси")]
    [InlineData("номер двигателя")]
    [InlineData("двигатель рақами")]
    [InlineData("номер кузова")]
    [InlineData("кузов рақами")]
    [InlineData("шасси рақами")]
    public void Vin_brand_plate_engine_body_and_chassis_number_stay_askable_when_required(string label)
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
        Assert.Equal(FieldCategory.DocumentOnly, Classify("рама", AgreementFieldMode.Required));
        Assert.Equal(FieldCategory.DocumentOnly, Classify("рама", AgreementFieldMode.Optional));
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

    /// <summary>
    /// The new vehicle_sale_agreement.json fields (VIN, color, special
    /// marks, transfer date, payment method) added for a richer interview
    /// flow - all genuinely askable, and the VIN label deliberately avoids
    /// the word "рама" (frame), which would otherwise collide with the
    /// chassis/frame-number DocumentOnly keyword.
    /// </summary>
    [Theory]
    [InlineData("Автотранспорт воситасининг VIN рақами")]
    [InlineData("Автотранспорт воситасининг ранги")]
    [InlineData("Автотранспорт воситасининг ажралиб турувчи белгилари")]
    [InlineData("Битимнинг қўшимча шартлари")]
    public void New_vehicle_sale_fields_stay_askable_as_required_object(string label)
    {
        Assert.Equal(FieldCategory.RequiredObject, Classify(label));
    }

    [Fact]
    public void New_vehicle_sale_time_and_commercial_fields_classify_correctly()
    {
        Assert.Equal(FieldCategory.RequiredTime, Classify("Автотранспорт воситасини топшириш санаси"));
        Assert.Equal(FieldCategory.RequiredCommercial, Classify("Тўлов қандай амалга оширилади"));
    }

    /// <summary>
    /// Certificate/license reference fields found across family (marriage/
    /// birth certificates) and court (attorney license) templates - printed
    /// on a document, never recalled from memory, same reasoning as the
    /// vehicle registration-certificate metadata above but for a generic
    /// certificate/license rather than a vehicle's own.
    /// </summary>
    [Theory]
    [InlineData("Гувоҳнома рақами")]
    [InlineData("Гувоҳнома берилган сана")]
    [InlineData("Ишончнома олувчига адвокатлик лицензиясини берган адлия бошқармаси")]
    [InlineData("Адвокатлик лицензия рақами")]
    public void Certificate_and_license_reference_fields_are_document_only(string label)
    {
        Assert.Equal(FieldCategory.DocumentOnly, Classify(label));
    }

    /// <summary>
    /// The marriage date itself (not the certificate's own reference data)
    /// stays askable - only the certificate's metadata is document-only.
    /// </summary>
    [Fact]
    public void Marriage_date_itself_stays_askable()
    {
        Assert.Equal(FieldCategory.RequiredTime, Classify("Қонуний никоҳдан ўтилган сана"));
    }

    /// <summary>
    /// A franchise agreement's license fee ("Лицензия комплекси учун
    /// тўланадиган ҳақ миқдори") also contains "лицензия", but it's the
    /// deal's actual price, not a reference to an existing license read
    /// off a document - it must stay askable, not fall through to
    /// DocumentOnly alongside genuine license-reference fields.
    /// </summary>
    [Fact]
    public void License_fee_amount_stays_askable_as_commercial()
    {
        Assert.Equal(FieldCategory.RequiredCommercial, Classify("Лицензия комплекси учун тўланадиган ҳақ миқдори"));
    }

    [Theory]
    [InlineData("Шикоят берувчи юридик шахс номи ва ташкилий ҳуқуқий шакли")] // court: appellant org identity
    [InlineData("Сотувчи корхонанинг юридик манзили")] // business: company legal address
    [InlineData("Буйруқ рақами")] // employment: order-decree number
    [InlineData("Буйруқ қабул қилинган сана")] // employment: order-decree date
    [InlineData("Буйруқ қабул қилинган жой")] // employment: order-decree place
    public void Compound_identity_and_order_metadata_fields_are_never_asked(string label)
    {
        Assert.Equal(FieldCategory.NeverAsk, Classify(label));
    }

    /// <summary>
    /// The employee's assigned company car's plate/model stay askable (like
    /// a vehicle sale's own VIN/plate) - the interview offers a document
    /// upload alternative, it doesn't hard-exclude them.
    /// </summary>
    [Theory]
    [InlineData("Ходимга бириктирилаётган автомашина рақам белгиси")]
    [InlineData("Ходимга бириктирилаётган автомашина русуми")]
    public void Assigned_company_car_fields_stay_askable(string label)
    {
        Assert.Equal(FieldCategory.RequiredObject, Classify(label));
    }
}