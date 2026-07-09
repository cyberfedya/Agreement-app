using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Profile;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Profile;

public sealed class SaveUserProfileUseCase(IUserProfileRepository repository)
{
    public async Task<UserProfileDto> ExecuteAsync(
        string id, SaveUserProfileRequest request, CancellationToken cancellationToken = default)
    {
        var saved = await repository.UpsertAsync(
            new UserProfile
            {
                Id = id,
                FullName = request.FullName.Trim(),
                PassportNumber = request.PassportNumber.Trim(),
                BirthDate = request.BirthDate.Trim(),
                Address = request.Address.Trim(),
                UpdatedAt = DateTime.UtcNow,
            },
            cancellationToken);

        return new UserProfileDto(saved.Id, saved.FullName, saved.PassportNumber, saved.BirthDate, saved.Address);
    }
}
