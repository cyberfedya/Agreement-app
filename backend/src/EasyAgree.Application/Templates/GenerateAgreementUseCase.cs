using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Templates;

public sealed class GenerateAgreementUseCase(IAgreementTemplateRepository repository)
{
    public async Task<GenerateAgreementResult> ExecuteAsync(
        string key, IReadOnlyDictionary<int, string> answers, CancellationToken cancellationToken = default)
    {
        var template = await repository.GetByKeyAsync(key, cancellationToken);
        if (template is null)
            return GenerateAgreementResult.NotFound();

        var missingFieldIds = template.Fields
            .Where(f => f.Mode == AgreementFieldMode.Required)
            .Select(f => f.FieldId)
            .Where(fieldId => !answers.TryGetValue(fieldId, out var value) || string.IsNullOrWhiteSpace(value))
            .OrderBy(fieldId => fieldId)
            .ToList();

        if (missingFieldIds.Count > 0)
            return GenerateAgreementResult.MissingFields(missingFieldIds);

        var html = AgreementPlaceholderParser.ReplacePlaceholders(template.HtmlTemplate, answers);
        return GenerateAgreementResult.Success(html);
    }
}
