using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common.Interfaces;

public interface IDealRepository
{
    Task<Deal> AddAsync(Deal deal, CancellationToken cancellationToken = default);

    Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task UpdateAsync(Deal deal, CancellationToken cancellationToken = default);

    /// <summary>Deals the profile created or joined as second party, newest-updated first.</summary>
    Task<(IReadOnlyList<Deal> Items, int TotalCount)> GetByProfileIdAsync(
        string profileId, int skip, int take, CancellationToken cancellationToken = default);
}
