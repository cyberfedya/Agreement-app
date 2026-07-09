using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Profile;

namespace EasyAgree.Application.Profile;

public sealed class GetUserProfileUseCase(IUserProfileRepository repository)
{
    public async Task<UserProfileDto?> ExecuteAsync(string id, CancellationToken cancellationToken = default)
    {
        var profile = await repository.GetAsync(id, cancellationToken);
        return profile is null
            ? null
            : new UserProfileDto(profile.Id, profile.FullName, profile.PassportNumber, profile.BirthDate, profile.Address);
    }
}
