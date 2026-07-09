namespace EasyAgree.Application.Common.Interfaces;

/// <summary>
/// The current user's verified identity — the data EasyAgree substitutes
/// into agreements as the creator's party details instead of asking for it
/// during the interview. The production implementation will be backed by
/// MyID; until then Infrastructure registers a fixed demo profile.
/// </summary>
public interface IUserProfileProvider
{
    Task<UserProfile> GetCurrentAsync(CancellationToken cancellationToken = default);
}

public sealed record UserProfile(
    string FullName,
    string PassportNumber,
    string PassportIssuedBy,
    string PassportIssueDate,
    string BirthDate,
    string Address);
