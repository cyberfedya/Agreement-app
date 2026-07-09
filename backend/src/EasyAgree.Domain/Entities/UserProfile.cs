namespace EasyAgree.Domain.Entities;

/// <summary>
/// A user's self-entered identity — substituted into agreements as the
/// creator's party details. Keyed by a client-generated id (there is no
/// account/auth system yet); a real MyID integration would key this by the
/// verified identity instead, but nothing downstream would change.
/// </summary>
public class UserProfile
{
    public required string Id { get; set; }

    public string FullName { get; set; } = "";

    public string PassportNumber { get; set; } = "";

    public string BirthDate { get; set; } = "";

    public string Address { get; set; } = "";

    public DateTime UpdatedAt { get; set; }
}
