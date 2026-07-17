using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// One field-extractable document a template's domain can recommend -
/// the label keywords identify which askable fields it would likely
/// fill, the hint keys identify whether it's already been provided (any
/// of these appearing in <see cref="EasyAgree.Application.Documents.DocumentFieldHintCollection"/>
/// counts as "already uploaded").
/// </summary>
public sealed record RecommendedDocument(DocumentType Type, IReadOnlyList<string> LabelKeywords, IReadOnlyList<string> HintKeys);

/// <summary>
/// Domain -> the one document worth suggesting mid-interview to save
/// manual typing. Deliberately self-contained and separate from
/// <c>DocumentRequirementResolver</c> (the pre-interview "what to
/// upload" screen) - that catalog answers "what might be useful",
/// this one answers the narrower question "what would the OCR pipeline
/// actually extract several fields from", so only domains where
/// <see cref="DocumentFieldMapper"/>-style extraction genuinely applies
/// are listed. A domain with no entry here (loan, employment, etc.)
/// never gets a suggestion.
/// </summary>
public static class DocumentSuggestionCatalog
{
    private static readonly Dictionary<string, RecommendedDocument> ByDomain = new()
    {
        ["vehicle"] = new RecommendedDocument(
            DocumentType.VehicleRegistration,
            LabelKeywords:
            [
                "vin рақами", "кузов рақами", "кузов раками", "шасси рақами", "шасси раками",
                "двигатель рақами", "двигател рақами", "давлат рақам", "русуми",
                "ишлаб чиқарилган йил", "рамка рақами",
            ],
            HintKeys: ["vin", "body_number", "chassis_number", "engine_number", "plate_number", "brand", "model", "year"]),

        ["real_estate"] = new RecommendedDocument(
            DocumentType.Cadastre,
            LabelKeywords: ["кадастр", "майдони", "хоналар сони", "қавати"],
            HintKeys: ["cadastre_number", "area", "rooms", "floor"]),

        ["inheritance"] = new RecommendedDocument(
            DocumentType.Certificate,
            LabelKeywords: ["вафот санаси", "вафот этган сана", "ўлим санаси", "вафот этган куни"],
            HintKeys: ["death_date", "deceased_full_name"]),

        // Company-car assignment orders ask for exactly the vehicle's plate
        // + model - the same extraction pipeline as a vehicle sale.
        ["employment"] = new RecommendedDocument(
            DocumentType.VehicleRegistration,
            LabelKeywords: ["автомашина рақам белгиси", "автомашина русуми"],
            HintKeys: ["plate_number", "brand", "model"]),

        ["business"] = new RecommendedDocument(
            DocumentType.Invoice,
            LabelKeywords: ["ускунанинг русуми", "ускунанинг номи", "ускуна сони"],
            HintKeys: ["equipment_model", "equipment_name"]),

        ["family"] = new RecommendedDocument(
            DocumentType.Certificate,
            LabelKeywords: ["гувоҳнома рақами", "гувоҳнома берилган сана", "никоҳдан ўтилган сана", "туғилган санаси"],
            HintKeys: ["certificate_number", "certificate_date"]),
    };

    public static RecommendedDocument? ForDomain(string domain) =>
        ByDomain.TryGetValue(domain, out var doc) ? doc : null;
}
