using EasyAgree.Application.Documents;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals.Interview;

public sealed record DocumentSuggestionDecision(DocumentType DocumentType, int MatchedFieldCount);

/// <summary>
/// Deterministically decides whether to interrupt the interview with a
/// document-upload suggestion instead of the next question. Called once
/// per turn, before question generation - never mid-catch-up, never
/// twice for a document the user already dismissed or provided.
/// </summary>
public static class DocumentSuggestionEngine
{
    /// <summary>Below this, typing the remaining fields by hand is no slower than a photo + review.</summary>
    private const int MinMatchedFields = 3;

    public static DocumentSuggestionDecision? Evaluate(
        string templateDomain,
        IReadOnlyList<ClassifiedField> askable,
        DocumentFieldHintCollection documentHints,
        ISet<string> dismissedDocumentTypes)
    {
        var recommended = DocumentSuggestionCatalog.ForDomain(templateDomain);
        if (recommended is null)
            return null;

        var typeKey = recommended.Type.ToString();
        if (dismissedDocumentTypes.Contains(typeKey))
            return null;

        // Any hint for this document's vocabulary already present - even
        // partially extracted - means the user already provided it; never
        // ask again for the same document within one deal.
        var alreadyProvided = documentHints.Fields.Any(f => recommended.HintKeys.Contains(f.Key));
        if (alreadyProvided)
            return null;

        var matchedCount = askable.Count(f => MatchesAny(f.Label.ToLowerInvariant(), recommended.LabelKeywords));
        if (matchedCount < MinMatchedFields)
            return null;

        return new DocumentSuggestionDecision(recommended.Type, matchedCount);
    }

    private static bool MatchesAny(string label, IReadOnlyList<string> keywords) => keywords.Any(label.Contains);
}
