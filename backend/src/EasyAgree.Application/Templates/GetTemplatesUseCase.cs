using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Application.Templates;

public sealed class GetTemplatesUseCase(IAgreementTemplateRepository repository)
{
    public async Task<IReadOnlyList<TemplateSummaryDto>> ExecuteAsync(
        string language, CancellationToken cancellationToken = default)
    {
        var templates = await repository.GetActiveAsync(cancellationToken);

        return templates
            .Select(t =>
            {
                var (title, description) = TranslationResolver.Resolve(t.Translations, language);
                return new TemplateSummaryDto(t.Key, t.Domain, title, description);
            })
            .ToList();
    }
}
