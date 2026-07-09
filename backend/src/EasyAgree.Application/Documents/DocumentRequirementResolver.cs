using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

/// <summary>
/// Rule-based, keyword-driven - deliberately not a per-template database
/// column, so the existing 418 templates never need touching. Matches on
/// both the template's (English) key slug and its (Russian/Uzbek) title
/// for robustness. Never suggests an identity document (passport/PINFL/ID)
/// - those come from the account profile, never from a scan.
/// </summary>
public sealed class DocumentRequirementResolver : IDocumentRequirementResolver
{
    public IReadOnlyList<RequiredDocument> Resolve(string templateKey, string templateTitle)
    {
        var text = $"{templateKey} {templateTitle}".ToLowerInvariant();

        if (Contains(text, "vehicle", "автомоб", "автотранс", "прицеп", "trailer"))
        {
            return
            [
                new RequiredDocument(DocumentType.VehicleRegistration, "Техпаспорт автомобиля",
                    "Свидетельство о регистрации транспортного средства", Required: true, Priority: 1),
                new RequiredDocument(DocumentType.VehiclePassport, "ПТС",
                    "Паспорт транспортного средства, если есть", Required: false, Priority: 2),
            ];
        }

        if (Contains(text, "house", "apartment", "real_estate", "building", "property",
                "дом", "квартир", "недвиж", "здани", "помещен"))
        {
            return
            [
                new RequiredDocument(DocumentType.Cadastre, "Кадастровый документ",
                    "Кадастровая справка или выписка на объект", Required: true, Priority: 1),
                new RequiredDocument(DocumentType.OwnershipCertificate, "Свидетельство о праве собственности",
                    "Документ, подтверждающий право собственности", Required: true, Priority: 2),
                new RequiredDocument(DocumentType.TechnicalPassport, "Технический паспорт",
                    "Технический паспорт объекта, если есть", Required: false, Priority: 3),
            ];
        }

        if (Contains(text, "loan", "займ", "кредит", "ссуд"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Расписка или прежний договор",
                    "Расписка, ранее заключённый договор или иное подтверждение долга, если есть",
                    Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "employment", "labor", "labour", "труд", "работ"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Должностная инструкция или приказ",
                    "Внутренний документ компании о должности, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "service", "услуг"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Техническое задание или смета",
                    "Описание объёма работ или смета, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "construction", "строител"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Проектная документация или смета",
                    "Чертежи, проект или смета, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "insurance", "страхован"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Страховой полис",
                    "Действующий страховой полис или акт осмотра, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "inheritance", "will", "наслед", "завещан"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Свидетельство о наследстве",
                    "Документ о праве на наследство, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "claim", "court", "lawsuit", "иск", "жалоб", "суд"))
        {
            return
            [
                new RequiredDocument(DocumentType.SupportingDocument, "Материалы дела",
                    "Документы и доказательства по делу, если есть", Required: false, Priority: 1),
            ];
        }

        if (Contains(text, "enterprise", "company", "предприят", "компани"))
        {
            return
            [
                new RequiredDocument(DocumentType.CompanyRegistration, "Регистрационные документы компании",
                    "Свидетельство о регистрации юридического лица, если применимо", Required: false, Priority: 1),
                new RequiredDocument(DocumentType.TaxCertificate, "Справка о постановке на налоговый учёт",
                    "Если применимо", Required: false, Priority: 2),
            ];
        }

        return [];
    }

    private static bool Contains(string haystack, params string[] needles) => needles.Any(haystack.Contains);
}
