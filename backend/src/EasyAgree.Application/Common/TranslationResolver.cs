using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common;

public static class TranslationResolver
{
    /// <summary>Picks the translation matching the requested language, falling back to any available one.</summary>
    public static (string Title, string Description) Resolve(
        IEnumerable<AgreementTemplateTranslation> translations, string language)
    {
        var match = translations.FirstOrDefault(t => string.Equals(t.Language, language, StringComparison.OrdinalIgnoreCase))
            ?? translations.FirstOrDefault();

        return match is null ? (string.Empty, string.Empty) : (match.Title, match.Description);
    }
}
