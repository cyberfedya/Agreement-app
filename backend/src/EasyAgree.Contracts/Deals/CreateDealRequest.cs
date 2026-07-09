namespace EasyAgree.Contracts.Deals;

/// <summary>Provide exactly one of <see cref="Text"/> (AI-matched) or <see cref="TemplateKey"/> (direct pick).</summary>
public sealed record CreateDealRequest(string? Text, string? TemplateKey, string? ProfileId);
