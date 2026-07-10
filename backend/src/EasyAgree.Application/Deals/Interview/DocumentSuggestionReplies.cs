using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>Localized copy for the mid-interview document-upload suggestion card.</summary>
public static class DocumentSuggestionReplies
{
    public static string Title(DocumentType documentType, string language) => documentType switch
    {
        DocumentType.VehicleRegistration => language switch
        {
            "uz" => "Транспорт воситасини рўйхатдан ўтказиш гувоҳномасини юкланг",
            "en" => "Upload the vehicle registration certificate",
            _ => "Загрузите техпаспорт транспортного средства",
        },
        DocumentType.Cadastre => language switch
        {
            "uz" => "Кадастр ҳужжатини юкланг",
            "en" => "Upload the cadastre certificate",
            _ => "Загрузите кадастровый документ",
        },
        DocumentType.Certificate => language switch
        {
            "uz" => "Вафот тўғрисидаги гувоҳномани юкланг",
            "en" => "Upload the death certificate",
            _ => "Загрузите свидетельство о смерти",
        },
        _ => language switch
        {
            "uz" => "Ҳужжат юкланг",
            "en" => "Upload a document",
            _ => "Загрузите документ",
        },
    };

    public static string Description(DocumentType documentType, string language) => documentType switch
    {
        DocumentType.VehicleRegistration => language switch
        {
            "uz" => "Фото ёки PDF юкласангиз, кўпгина маълумотларни ўзим тўлдираман - қўлда киритиш шарт эмас.",
            "en" => "Upload a photo or PDF and I can fill in most of the vehicle details automatically - no need to type them by hand.",
            _ => "Мы можем автоматически заполнить большинство данных о транспортном средстве. Загрузите фото или PDF, и не придётся вводить их вручную.",
        },
        DocumentType.Cadastre => language switch
        {
            "uz" => "Фото ёки PDF юкласангиз, объект бўйича маълумотларни ўзим тўлдираман.",
            "en" => "Upload a photo or PDF and I can fill in most of the property details automatically.",
            _ => "Мы можем автоматически заполнить большинство данных об объекте. Загрузите фото или PDF кадастрового документа.",
        },
        DocumentType.Certificate => language switch
        {
            "uz" => "Фото ёки PDF юкласангиз, вафот санаси каби маълумотларни ўзим тўлдираман.",
            "en" => "Upload a photo or PDF and I can fill in details like the date automatically.",
            _ => "Мы можем автоматически заполнить часть данных, например дату. Загрузите фото или PDF документа.",
        },
        _ => language switch
        {
            "uz" => "Фото ёки PDF юкласангиз, баъзи майдонларни ўзим тўлдираман.",
            "en" => "Upload a photo or PDF and I can fill in some of the fields automatically.",
            _ => "Загрузите фото или PDF, и я смогу заполнить часть полей автоматически.",
        },
    };
}
