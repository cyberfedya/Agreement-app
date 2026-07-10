namespace EasyAgree.Domain.Enums;

/// <summary>
/// Where the second party is in accepting the deal they were invited to
/// via QR - deliberately just the states needed for the MVP invite screen
/// (accept/decline before viewing the agreement). Richer states
/// (Expired, Revoked) can be added later without touching this set.
/// </summary>
public enum InviteStatus
{
    Pending = 0,
    Opened = 1,
    Accepted = 2,
    Declined = 3,
}
