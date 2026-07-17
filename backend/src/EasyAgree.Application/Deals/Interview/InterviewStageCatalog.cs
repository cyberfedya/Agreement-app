namespace EasyAgree.Application.Deals.Interview;

/// <summary>One stage header the interview can show, already localized.</summary>
public sealed record InterviewStage(string Key, string Icon, string Label);

/// <summary>
/// Every askable field belongs to one of two conversational stages: first
/// the deal's object/subject itself (what's being sold/rented/lent/built),
/// then its terms (price, dates, payment, legal conditions). This mirrors
/// <see cref="FieldCategory.RequiredObject"/> vs
/// <see cref="FieldCategory.RequiredTime"/>/<see cref="FieldCategory.RequiredCommercial"/>
/// - no extra classification pass needed, no InterviewPlanner change.
///
/// Icon and label are per-domain so the UI reads naturally for any
/// template ("🚗 Автомобиль" for a vehicle sale, "💰 Заём" → "📄 Условия
/// возврата" for a loan, and so on) - adding a new domain's stage names is
/// a one-line entry here, not a code change anywhere else. Domains with no
/// entry fall back to a generic "Предмет договора" / "Условия договора"
/// pair so every one of the 418 templates gets a sensible stage header for
/// free, not just the ones listed explicitly.
/// </summary>
public static class InterviewStageCatalog
{
    private sealed record StagePair(StageTemplate Object, StageTemplate Terms);

    private sealed record StageTemplate(string Key, string Icon, IReadOnlyDictionary<string, string> Label);

    private static readonly IReadOnlyDictionary<string, StagePair> ByDomain =
        new Dictionary<string, StagePair>(StringComparer.OrdinalIgnoreCase)
        {
            ["vehicle"] = new StagePair(
                new StageTemplate("object", "🚗", Label("Автомобиль", "Автомобиль", "Vehicle")),
                new StageTemplate("terms", "📄", Label("Условия сделки", "Битим шартлари", "Deal terms"))),
            ["real_estate"] = new StagePair(
                new StageTemplate("object", "🏠", Label("Объект недвижимости", "Кўчмас мулк объекти", "Property")),
                new StageTemplate("terms", "📄", Label("Условия сделки", "Битим шартлари", "Deal terms"))),
            ["loan"] = new StagePair(
                new StageTemplate("object", "💰", Label("Заём", "Қарз", "Loan")),
                new StageTemplate("terms", "📄", Label("Условия возврата", "Қайтариш шартлари", "Repayment terms"))),
            ["services"] = new StagePair(
                new StageTemplate("object", "🛠️", Label("Услуга", "Хизмат", "Service")),
                new StageTemplate("terms", "📄", Label("Условия оказания услуги", "Хизмат кўрсатиш шартлари", "Service terms"))),
            ["employment"] = new StagePair(
                new StageTemplate("object", "📋", Label("Кадровое действие", "Кадрлар бўйича амал", "Employment action")),
                new StageTemplate("terms", "📄", Label("Детали оформления", "Расмийлаштириш тафсилотлари", "Filing details"))),
            ["business"] = new StagePair(
                new StageTemplate("object", "📦", Label("Предмет сделки", "Битим предмети", "Deal subject")),
                new StageTemplate("terms", "📄", Label("Условия сделки", "Битим шартлари", "Deal terms"))),
            ["court"] = new StagePair(
                new StageTemplate("object", "⚖️", Label("Суть обращения", "Мурожаат моҳияти", "Substance of the filing")),
                new StageTemplate("terms", "📄", Label("Формальные детали", "Расмий тафсилотлар", "Formal details"))),
            ["family"] = new StagePair(
                new StageTemplate("object", "👪", Label("Обстоятельства", "Ҳолат", "Circumstances")),
                new StageTemplate("terms", "📄", Label("Формальные детали", "Расмий тафсилотлар", "Formal details"))),
        };

    private static readonly StagePair Default = new(
        new StageTemplate("object", "📋", Label("Предмет договора", "Шартнома предмети", "Subject")),
        new StageTemplate("terms", "📄", Label("Условия договора", "Шартнома шартлари", "Terms")));

    private static Dictionary<string, string> Label(string ru, string uz, string en) =>
        new() { ["ru"] = ru, ["uz"] = uz, ["en"] = en };

    /// <summary>
    /// The stage a currently-asked field belongs to, or null for a field
    /// category that's never the "current question" shown to the user
    /// (never-asked/document-only/optional fields have no stage header).
    /// </summary>
    public static InterviewStage? Resolve(string domain, FieldCategory category, string language)
    {
        if (category is not (FieldCategory.RequiredObject or FieldCategory.RequiredTime or FieldCategory.RequiredCommercial))
            return null;

        var pair = ByDomain.GetValueOrDefault(domain, Default);
        var template = category == FieldCategory.RequiredObject ? pair.Object : pair.Terms;
        var label = template.Label.TryGetValue(language, out var value) ? value : template.Label["ru"];
        return new InterviewStage(template.Key, template.Icon, label);
    }
}
