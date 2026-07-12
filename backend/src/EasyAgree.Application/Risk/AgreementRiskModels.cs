namespace EasyAgree.Application.Risk;

public sealed record RiskCategory(string Name, int Risk, string Reason);
public sealed record AgreementRiskIssue(
    string Code, string Severity, string? Field, string Title, string Description,
    string RecommendedAction, bool CanAutoFix);
public sealed record AgreementRiskRecommendation(string IssueCode, string Message, string Importance);
public sealed record AgreementRiskAssessment(
    int OverallRisk, string RiskLevel, int Confidence, string Summary,
    IReadOnlyList<RiskCategory> Categories,
    IReadOnlyList<AgreementRiskIssue> Issues,
    IReadOnlyList<AgreementRiskRecommendation> Recommendations);
