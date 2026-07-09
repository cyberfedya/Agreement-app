namespace EasyAgree.Contracts.Profile;

public sealed record UserProfileDto(string Id, string FullName, string PassportNumber, string BirthDate, string Address);

public sealed record SaveUserProfileRequest(string FullName, string PassportNumber, string BirthDate, string Address);
