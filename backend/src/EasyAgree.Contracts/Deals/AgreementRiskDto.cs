namespace EasyAgree.Contracts.Deals;

public sealed record RiskCategoryDto(string Name, int Risk, string Reason);
public sealed record AgreementRiskIssueDto(
    string Code, string Severity, string? Field, string Title, string Description,
    string RecommendedAction, bool CanAutoFix);
public sealed record AgreementRiskRecommendationDto(string IssueCode, string Message, string Importance);
public sealed record AgreementRiskDto(
    int OverallRisk, string RiskLevel, int Confidence, string Summary,
    IReadOnlyList<RiskCategoryDto> Categories,
    IReadOnlyList<AgreementRiskIssueDto> Issues,
    IReadOnlyList<AgreementRiskRecommendationDto> Recommendations);
