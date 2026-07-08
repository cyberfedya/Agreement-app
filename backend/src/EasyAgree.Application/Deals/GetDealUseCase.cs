using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Deals;

namespace EasyAgree.Application.Deals;

public sealed class GetDealUseCase(IDealRepository dealRepository, IAgreementTemplateRepository templateRepository)
{
    public async Task<DealDto?> ExecuteAsync(Guid id, string language, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(id, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        var title = template is null ? deal.TemplateKey : TranslationResolver.Resolve(template.Translations, language).Title;

        return new DealDto(deal.Id, deal.TemplateKey, title, deal.Status.ToString());
    }
}
