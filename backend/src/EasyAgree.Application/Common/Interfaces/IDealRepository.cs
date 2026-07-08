using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common.Interfaces;

public interface IDealRepository
{
    Task<Deal> AddAsync(Deal deal, CancellationToken cancellationToken = default);

    Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task UpdateAsync(Deal deal, CancellationToken cancellationToken = default);
}
