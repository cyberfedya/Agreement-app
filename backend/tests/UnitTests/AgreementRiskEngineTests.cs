using EasyAgree.Application.Documents;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Risk;
using EasyAgree.Application.Validation;

namespace UnitTests;

public sealed class AgreementRiskEngineTests
{
    [Fact]
    public void Complete_signed_consistent_agreement_has_low_deterministic_risk()
    {
        var validation = new AgreementValidationResult(true, []);
        var quality = new AgreementQualityScore(100, 1, .5, .5, 1, 1, []);

        var assessment = AgreementRiskEngine.Assess(validation, quality, [], true, true);

        Assert.Equal("LOW", assessment.RiskLevel);
        Assert.Equal(100, assessment.Confidence);
        Assert.Empty(assessment.Issues);
    }

    [Fact]
    public void Risk_issues_produce_recommendations_linked_to_their_issue()
    {
        var validation = new AgreementValidationResult(false,
            [new AgreementValidationIssue("MISSING_REQUIRED_FIELD", "ERROR", 2, "sale price", "Missing", "Provide price")]);
        var quality = new AgreementQualityScore(30, .5, 0, .5, .25, .6, []);
        IReadOnlyList<DocumentConflict> conflicts = [new DocumentConflict("VIN_MISMATCH", "vin", "HIGH", "Documents disagree", "Verify VIN", [])];

        var assessment = AgreementRiskEngine.Assess(validation, quality, conflicts, false, false);

        Assert.True(assessment.OverallRisk >= 25);
        Assert.Contains(assessment.Issues, issue => issue.Code == "CONFLICT_VIN_MISMATCH");
        Assert.All(assessment.Recommendations, recommendation =>
            Assert.Contains(assessment.Issues, issue => issue.Code == recommendation.IssueCode));
    }
}
