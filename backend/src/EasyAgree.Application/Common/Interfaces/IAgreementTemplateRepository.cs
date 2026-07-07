using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common.Interfaces;

public interface IAgreementTemplateRepository
{
    Task<IReadOnlyList<AgreementTemplate>> GetActiveAsync(CancellationToken cancellationToken = default);

    Task<AgreementTemplate?> GetByKeyAsync(string key, CancellationToken cancellationToken = default);
}
