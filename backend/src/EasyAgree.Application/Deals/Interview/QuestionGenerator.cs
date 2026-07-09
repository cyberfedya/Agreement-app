using System.Text.Json;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals.Interview;

public sealed record GeneratedQuestion(string? Question, IReadOnlyDictionary<int, string> Extracted);

/// <summary>
/// Turns one CURRENT_QUESTION_GROUP into a single natural question (or
/// none, if the answer is already known) via the LLM. This is the only
/// place that talks to the model - whether a field is askable at all,
/// and in what order, is decided upstream by <see cref="FieldEligibilityEngine"/>
/// and <see cref="QuestionPriorityEngine"/>, not by the model.
/// </summary>
public sealed class QuestionGenerator(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You are an experienced Uzbek contract lawyer preparing the first draft of an agreement for a client,
        in the style of a real legal-services consultation - not a government questionnaire and not a form
        wizard. You never robotically read out a field's technical label.

        You are told CURRENT_QUESTION_GROUP: one or more related fields that must be asked about right now.
        Combine them into ONE short, natural, conversational question when they clearly belong together
        (e.g. two fields "room count" and "total area" become "Can you briefly describe the apartment - how
        many rooms and what's the total area?"). If the group has only one field, ask about just that one
        naturally. Never sound bureaucratic or legalistic - prefer "What price did you agree on?" over
        "Specify the amount of consideration."

        ALREADY_KNOWN lists what has already been established this conversation - never ask about any of it.

        Extraction rules (both are optional, use only what genuinely applies):
        - If USER_REQUEST already states the value of ANY field listed in ALL_ELIGIBLE_FIELDS (not just the
          current group), return it in "extracted" - lightly normalized, never guessed or invented.
        - If CURRENT_MESSAGE (the user's answer to the question you asked last turn) states the value of a
          field in CURRENT_QUESTION_GROUP, return it in "extracted" too. Never use CURRENT_MESSAGE to fill a
          field outside CURRENT_QUESTION_GROUP, even if it superficially resembles one - an answer about one
          topic must never be reused for a different field just because both mention a date or a place.
        - If everything in CURRENT_QUESTION_GROUP is already covered by "extracted", set "question" to null.

        "question" MUST be written strictly in the language given by LANGUAGE (ru = Russian, uz = Uzbek,
        en = English), regardless of what language the field labels or the user's message are in.

        Output ONLY valid JSON, no Markdown, no explanations, matching exactly:
        {"question":"<natural question or null>","extracted":{"<fieldId>":"<value>"}}

        Omit "extracted" (or use {}) when nothing new can be extracted.
        """;

    public async Task<GeneratedQuestion> GenerateAsync(InterviewContext context, CancellationToken cancellationToken)
    {
        var userMessage = BuildUserMessage(context);
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);
        return Parse(raw);
    }

    private static string BuildUserMessage(InterviewContext context)
    {
        var groupCatalog = string.Join('\n', context.CurrentGroup.Select(f => $"{f.FieldId}: {f.Label}"));
        var eligibleCatalog = string.Join('\n', context.AllEligible.Select(f => $"{f.FieldId}: {f.Label}"));
        var knownCatalog = context.AlreadyKnown.Count == 0
            ? "(none yet)"
            : string.Join('\n', context.AlreadyKnown.Select(kv => $"{kv.Key} = {kv.Value}"));

        return $"""
            CATEGORY: {context.TemplateTitle}
            LANGUAGE: {context.Language}
            USER_REQUEST: {context.UserRequest ?? "(not provided - template was picked manually)"}
            ALREADY_KNOWN:
            {knownCatalog}
            ALL_ELIGIBLE_FIELDS:
            {eligibleCatalog}
            CURRENT_QUESTION_GROUP:
            {groupCatalog}
            CURRENT_MESSAGE: {context.CurrentMessage ?? "(interview just started)"}
            """;
    }

    private static GeneratedQuestion Parse(string raw)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var question = root.TryGetProperty("question", out var qEl) && qEl.ValueKind == JsonValueKind.String
                ? qEl.GetString()
                : null;

            var extracted = new Dictionary<int, string>();
            if (root.TryGetProperty("extracted", out var extractedEl) && extractedEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in extractedEl.EnumerateObject())
                {
                    if (int.TryParse(prop.Name, out var fieldId) && prop.Value.ValueKind == JsonValueKind.String)
                        extracted[fieldId] = prop.Value.GetString()!;
                }
            }

            return new GeneratedQuestion(question, extracted);
        }
        catch (JsonException)
        {
            return new GeneratedQuestion(null, new Dictionary<int, string>());
        }
    }
}
