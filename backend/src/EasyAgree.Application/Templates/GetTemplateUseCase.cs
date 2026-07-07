using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Application.Templates;

public sealed class GetTemplateUseCase(IAgreementTemplateRepository repository)
{
    public async Task<TemplateDetailDto?> ExecuteAsync(
        string key, string language, CancellationToken cancellationToken = default)
    {
        var template = await repository.GetByKeyAsync(key, cancellationToken);
        if (template is null)
            return null;

        var (title, description) = TranslationResolver.Resolve(template.Translations, language);
        return new TemplateDetailDto(template.Key, template.Domain, title, description, template.SourceUrl);
    }
}
