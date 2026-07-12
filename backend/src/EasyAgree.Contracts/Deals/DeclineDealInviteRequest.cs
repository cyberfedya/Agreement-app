namespace EasyAgree.Contracts.Deals;

public sealed record DeclineDealInviteRequest(string? Reason, string? ProfileId);
