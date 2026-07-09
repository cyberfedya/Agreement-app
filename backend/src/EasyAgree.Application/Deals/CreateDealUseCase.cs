using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Deals;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Starts an agreement-creation session. Either matches a free-form request
/// to a template via the connected LLM, or accepts a manually-picked
/// template key directly — both paths converge on the same persisted
/// <see cref="Deal"/>, so the interview flow never needs to know which one
/// was used.
/// </summary>
public sealed class CreateDealUseCase(
    IAgreementTemplateRepository templateRepository,
    IDealRepository dealRepository,
    IAiChatClient aiChatClient)
{
    private const string ClassifierSystemPrompt = """
        You classify a user's free-form request into exactly one legal agreement template from the provided catalog.
        Match the template scope precisely: residential property (квартира, дом, жильё) must never map to a
        non-residential-premises template (нежилое помещение, офис, склад) and vice versa; prefer the most
        specific matching template, falling back to a general one only when no specific template fits.
        Respond with ONLY the template's key on a single line - nothing else, no punctuation, no explanation.
        If nothing in the catalog reasonably matches the request, respond with exactly: NONE
        """;

    public async Task<CreateDealResult> ExecuteAsync(
        string? text, string? templateKey, string language, CancellationToken cancellationToken = default)
    {
        AgreementTemplate? template;

        if (!string.IsNullOrWhiteSpace(templateKey))
        {
            template = await templateRepository.GetByKeyAsync(templateKey, cancellationToken);
        }
        else if (!string.IsNullOrWhiteSpace(text))
        {
            var candidates = await templateRepository.GetActiveAsync(cancellationToken);
            var matchedKey = await ClassifyAsync(text, candidates, language, cancellationToken);
            template = matchedKey is null ? null : candidates.FirstOrDefault(t => t.Key == matchedKey);
        }
        else
        {
            template = null;
        }

        if (template is null)
            return CreateDealResult.NoMatch();

        var now = DateTime.UtcNow;
        var deal = new Deal
        {
            Id = Guid.NewGuid(),
            TemplateKey = template.Key,
            RequestText = text,
            Status = DealStatus.Draft,
            CreatedAt = now,
            UpdatedAt = now,
        };
        await dealRepository.AddAsync(deal, cancellationToken);

        var (title, _) = TranslationResolver.Resolve(template.Translations, language);
        return CreateDealResult.Success(new DealDto(deal.Id, template.Key, title, deal.Status.ToString()));
    }

    /// <summary>Returns the matched template key, or null if the model found no reasonable match.</summary>
    private async Task<string?> ClassifyAsync(
        string text, IReadOnlyList<AgreementTemplate> candidates, string language, CancellationToken cancellationToken)
    {
        var catalog = string.Join(
            '\n',
            candidates.Select(t => $"{t.Key}: {TranslationResolver.Resolve(t.Translations, language).Title}"));

        var userMessage = $"Catalog:\n{catalog}\n\nUser request: {text}";
        var response = await aiChatClient.CompleteAsync(ClassifierSystemPrompt, userMessage, cancellationToken);
        var key = response.Trim();

        if (key.Equals("NONE", StringComparison.OrdinalIgnoreCase))
            return null;

        // Guard against the model hallucinating a key that isn't in the catalog.
        return candidates.Any(t => t.Key == key) ? key : null;
    }
}
