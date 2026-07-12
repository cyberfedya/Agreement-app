namespace EasyAgree.Application.Risk;

/// <summary>Maps an explainable issue to a non-mutating recommendation.</summary>
public static class AgreementRecommendationEngine
{
    public static IReadOnlyList<AgreementRiskRecommendation> Create(IEnumerable<AgreementRiskIssue> issues) =>
        issues.Select(issue => new AgreementRiskRecommendation(issue.Code, issue.RecommendedAction, issue.Severity)).ToList();
}
