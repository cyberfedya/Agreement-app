using EasyAgree.Application.Documents;
using EasyAgree.Application.Quality;

namespace UnitTests;

public sealed class AgreementQualityScoreEngineTests
{
    [Fact]
    public void Complete_consistent_agreement_scores_100()
    {
        var score = AgreementQualityScoreEngine.Calculate(4, 2, 2,
            [new DocumentFieldHint("vin", "XW8ZZZ61ZHG000001", 1, "document")], [], []);

        Assert.Equal(100, score.Score);
        Assert.Empty(score.Recommendations);
    }

    [Fact]
    public void Missing_fields_and_high_conflict_reduce_score_and_explain_why()
    {
        var conflict = new DocumentConflict("VIN_MISMATCH", "vin", "HIGH", "Different VINs", "Verify VIN", []);
        var score = AgreementQualityScoreEngine.Calculate(4, 1, 1,
            [new DocumentFieldHint("vin", "X", 0.60, "document")], [conflict], ["sale price", "transfer date"]);

        Assert.True(score.Score < 50);
        Assert.Contains(score.Recommendations, recommendation => recommendation.Code == "MISSING_REQUIRED_FIELD");
        Assert.Contains(score.Recommendations, recommendation => recommendation.Code == "RESOLVE_VIN_MISMATCH");
    }
}
