using EasyAgree.Application.Deals.Interview;

namespace UnitTests;

public sealed class FieldLabelTranslatorTests
{
    [Theory]
    [InlineData("Автотранспорт воситасининг VIN рақами", "ru", "VIN автомобиля")]
    [InlineData("Автотранспортнинг двигатель рақами", "ru", "номер двигателя автомобиля")]
    [InlineData("Автотранспортнинг кузов рақами", "ru", "номер кузова автомобиля")]
    [InlineData("Автотранспортнинг шасси рақами", "ru", "номер шасси автомобиля")]
    [InlineData("Автотранспорт воситасининг VIN рақами", "en", "vehicle VIN")]
    public void Known_labels_translate_out_of_uzbek(string label, string language, string expected)
    {
        Assert.Equal(expected, FieldLabelTranslator.Translate(label, language));
    }

    [Fact]
    public void Uzbek_interviews_keep_the_original_label()
    {
        Assert.Equal(
            "Автотранспортнинг двигатель рақами",
            FieldLabelTranslator.Translate("Автотранспортнинг двигатель рақами", "uz"));
    }

    [Fact]
    public void Unknown_labels_pass_through_unchanged()
    {
        Assert.Equal("Some new field label", FieldLabelTranslator.Translate("Some new field label", "ru"));
    }

    [Fact]
    public void Fallback_question_no_longer_leaks_untranslated_uzbek_text()
    {
        var question = ConversationReplies.FallbackQuestion("ru", "Автотранспорт воситасининг VIN рақами");

        Assert.Equal("Укажите, пожалуйста: VIN автомобиля", question);
        Assert.DoesNotContain("рақами", question);
    }
}
