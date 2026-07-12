namespace EasyAgree.Contracts.Deals;

public sealed record ProposeDealFieldChangeRequest(int FieldId, string ProposedValue, string? Reason, string? ProfileId);
