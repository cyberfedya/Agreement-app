using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common.Interfaces;

public interface IUserProfileRepository
{
    Task<UserProfile?> GetAsync(string id, CancellationToken cancellationToken = default);

    Task<UserProfile> UpsertAsync(UserProfile profile, CancellationToken cancellationToken = default);

    Task DeleteAsync(string id, CancellationToken cancellationToken = default);
}
