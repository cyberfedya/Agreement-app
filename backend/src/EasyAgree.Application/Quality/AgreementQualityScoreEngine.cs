using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Quality;

/// <summary>Pure scoring policy for a draft. The score is reproducible from
/// its supplied facts and never changes agreement data.</summary>
public static class AgreementQualityScoreEngine
{
    public static AgreementQualityScore Calculate(
        int requiredFieldCount,
        int manualRequiredFields,
        int automaticRequiredFields,
        IReadOnlyList<DocumentFieldHint> documentHints,
        IReadOnlyList<DocumentConflict> conflicts,
        IReadOnlyList<string> missingLabels)
    {
        var completed = manualRequiredFields + automaticRequiredFields;
        var requiredCompletion = Ratio(completed, requiredFieldCount);
        var automaticCompletion = Ratio(automaticRequiredFields, requiredFieldCount);
        var manualCompletion = Ratio(manualRequiredFields, requiredFieldCount);
        var documentConfidence = documentHints.Count == 0 ? 1.0 : documentHints.Average(hint => hint.Confidence);
        var consistency = Math.Max(0, 1.0 - conflicts.Sum(conflict => conflict.Severity switch
        {
            "HIGH" => 0.75,
            "MEDIUM" => 0.10,
            _ => 0.05,
        }));

        var score = (int)Math.Round(100 * (
            0.60 * requiredCompletion +
            0.25 * consistency +
            0.15 * documentConfidence), MidpointRounding.AwayFromZero);

        var recommendations = new List<QualityRecommendation>();
        foreach (var label in missingLabels.Take(10))
            recommendations.Add(new("MISSING_REQUIRED_FIELD", $"Provide a reliable value for {label}.", "HIGH"));
        foreach (var conflict in conflicts)
            recommendations.Add(new("RESOLVE_" + conflict.Type, conflict.RecommendedResolution, conflict.Severity));
        if (documentHints.Count > 0 && documentConfidence < 0.75)
            recommendations.Add(new("LOW_DOCUMENT_CONFIDENCE", "Review low-confidence extracted document values.", "MEDIUM"));

        return new AgreementQualityScore(score, requiredCompletion, automaticCompletion, manualCompletion, consistency, documentConfidence, recommendations);
    }

    private static double Ratio(int value, int total) => total == 0 ? 1.0 : Math.Clamp((double)value / total, 0, 1);
}
