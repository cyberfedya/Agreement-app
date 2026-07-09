using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

public sealed class GetRequiredDocumentsUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IDocumentRequirementResolver requirementResolver)
{
    public async Task<IReadOnlyList<RequiredDocument>?> ExecuteAsync(
        Guid dealId, string language, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var (title, _) = TranslationResolver.Resolve(template.Translations, language);
        return requirementResolver.Resolve(deal.TemplateKey, title);
    }
}
