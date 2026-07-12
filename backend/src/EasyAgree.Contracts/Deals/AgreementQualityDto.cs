namespace EasyAgree.Contracts.Deals;

public sealed record QualityRecommendationDto(string Code, string Message, string Importance);
public sealed record AgreementQualityDto(
    int Score,
    double RequiredCompletion,
    double AutomaticCompletion,
    double ManualCompletion,
    double Consistency,
    double DocumentConfidence,
    IReadOnlyList<QualityRecommendationDto> Recommendations);
