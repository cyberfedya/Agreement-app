namespace EasyAgree.Application.Legal;

/// <summary>A traceable fact produced without modifying its source value.</summary>
public sealed record LegalFact(
    string Key, string Original, string Normalized, double Confidence, string Source, string Status,
    string Reason, IReadOnlyList<string> DerivedFrom, DateTime? DerivedAt = null);
