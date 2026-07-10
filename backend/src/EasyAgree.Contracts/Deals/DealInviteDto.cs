namespace EasyAgree.Contracts.Deals;

public sealed record DealInviteDto(
    Guid DealId,
    string TransactionType,
    string? FirstPartyRole,
    string? ExpectedSecondPartyRole,
    string? InvitedBy,
    string InviteStatus,
    DateTime? ExpiresAt);
