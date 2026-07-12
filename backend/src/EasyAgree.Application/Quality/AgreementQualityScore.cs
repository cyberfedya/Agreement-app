namespace EasyAgree.Application.Quality;

public sealed record QualityRecommendation(string Code, string Message, string Importance);
public sealed record AgreementQualityScore(
    int Score,
    double RequiredCompletion,
    double AutomaticCompletion,
    double ManualCompletion,
    double Consistency,
    double DocumentConfidence,
    IReadOnlyList<QualityRecommendation> Recommendations);
