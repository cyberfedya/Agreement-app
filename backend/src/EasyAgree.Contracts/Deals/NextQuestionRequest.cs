namespace EasyAgree.Contracts.Deals;

/// <summary>
/// The answer to the field the previous call asked about, if any (omit
/// both on the very first call for a deal).
/// </summary>
public sealed record NextQuestionRequest(int? FieldId, string? Answer);
