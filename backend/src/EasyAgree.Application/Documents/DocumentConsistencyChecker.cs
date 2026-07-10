using System.Text.Json;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

/// <summary>
/// Catches the case where a user already described one specific
/// thing (in their opening request or an earlier answer) and then
/// uploads a document about something else entirely (wrong car, wrong
/// property, wrong person) - previously this failed silently: the
/// mismatched document's data was simply never used, with no
/// indication to the user of why the interview kept asking things
/// that were "right there in the photo".
/// </summary>
public sealed class DocumentConsistencyChecker(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You check whether a newly uploaded document is plausibly about the same real-world subject (the same
        car, property, person, company, etc.) as what the user has already told the agreement system, given
        in KNOWN_CONTEXT.

        Only flag a MISMATCH when there's a clear, concrete conflict - e.g. KNOWN_CONTEXT names one car brand
        and the document is unambiguously about a different brand/model, or KNOWN_CONTEXT names one person
        and the document is about someone else entirely. If KNOWN_CONTEXT is empty, too vague to compare, or
        the document simply adds detail without contradicting anything, answer MATCH.

        When in doubt, answer MATCH - a wrongly-flagged real document is worse than an occasional missed
        mismatch, since the user can always correct extracted fields by hand afterwards.

        Output ONLY valid JSON, no Markdown: {"result":"MATCH"} or {"result":"MISMATCH","reason":"<one short
        sentence in LANGUAGE explaining the concrete conflict, e.g. what document says vs what was already
        stated - never generic filler>"}
        """;

    public async Task<string?> CheckAsync(
        string? knownContext,
        string documentOcrText,
        IReadOnlyDictionary<string, ExtractedFieldValue> documentFields,
        string language,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(knownContext) || string.IsNullOrWhiteSpace(documentOcrText))
            return null;

        var fieldsSummary = documentFields.Count == 0
            ? "(none)"
            : string.Join('\n', documentFields.Select(kv => $"{kv.Key} = {kv.Value.Value}"));

        var userMessage = $"""
            LANGUAGE: {language}
            KNOWN_CONTEXT: {knownContext}
            DOCUMENT_FIELDS:
            {fieldsSummary}
            DOCUMENT_TEXT: {Truncate(documentOcrText, 1500)}
            """;

        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);
        return Parse(raw);
    }

    private static string Truncate(string text, int maxLength) =>
        text.Length <= maxLength ? text : text[..maxLength];

    private static string? Parse(string raw)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var result = root.TryGetProperty("result", out var resultEl) ? resultEl.GetString() : null;
            if (!string.Equals(result, "MISMATCH", StringComparison.OrdinalIgnoreCase))
                return null;

            var reason = root.TryGetProperty("reason", out var reasonEl) ? reasonEl.GetString() : null;
            return string.IsNullOrWhiteSpace(reason) ? null : reason;
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
