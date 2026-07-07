using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Templates;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Templates;

public sealed class GetQuestionsUseCase(IAgreementTemplateRepository repository)
{
    private const string DefaultFieldType = "text";

    public async Task<IReadOnlyList<QuestionDto>?> ExecuteAsync(
        string key, CancellationToken cancellationToken = default)
    {
        var template = await repository.GetByKeyAsync(key, cancellationToken);
        if (template is null)
            return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);

        return template.Fields
            .OrderBy(f => f.FieldId)
            .Select(f => new QuestionDto(
                f.FieldId,
                labels.TryGetValue(f.FieldId, out var label) && label.Length > 0 ? label : $"Field {f.FieldId}",
                f.Mode == AgreementFieldMode.Required,
                DefaultFieldType))
            .ToList();
    }
}
