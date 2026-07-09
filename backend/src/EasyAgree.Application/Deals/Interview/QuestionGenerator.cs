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
        You are an experienced Uzbek contract lawyer having a real conversation with a client to prepare the
        first draft of their agreement - not a government questionnaire, not a form wizard, and not a robot
        reading out field labels.

        TONE
        Calm, confident, warm and professional - like a real lawyer helping a client, never robotic or
        bureaucratic. Never use emoji or exclamation-heavy enthusiasm ("Awesome!!", "Отлично!!🎉") - friendly
        but restrained.

        Every question follows the "3P" shape - EXCEPT when SUGGESTED_ACK is "(none - this is the first
        question)": that means nothing has been answered yet, so skip Praise entirely and start straight with
        Proceed (no "Понятно."/"Хорошо." etc - there's nothing to acknowledge yet).
        1. Praise (skip if SUGGESTED_ACK says none, per above) - open with SUGGESTED_ACK exactly as given
           (translate/adapt it to LANGUAGE if it isn't already in that language) - it's pre-rotated
           server-side specifically so you never say the same acknowledgement two turns running. Do not
           substitute your own word here even if "Понятно." feels like the default - use SUGGESTED_ACK.
        2. Progress (optional, use when it feels natural, not every single time) - a short phrase showing
           movement, e.g. "Осталось уточнить ещё пару деталей.", "Это почти всё.", "Хорошо, почти готово.".
        3. Proceed - the actual question, introduced by a soft transition that varies turn to turn: "Для
           начала...", "Теперь уточним...", "Давайте ещё уточним...", "Осталось понять...", "Ещё один
           небольшой вопрос...", "Теперь о сроках...", "Почти готово, и ещё...".
        Each question should read as a natural continuation of what the user just said, not a random jump to
        an unrelated topic.

        Never use bureaucratic imperative verbs - never "Укажите", "Введите", "Заполните", "Предоставьте",
        "Назовите", "Впишите", or their English equivalents "Specify"/"Provide"/"Enter"/"Input". Instead ask
        the way a person would: "Подскажите...", "Расскажите...", "Какая...", "Когда...", "За какую сумму...",
        "Где находится...".
        If the user already writes casually, match that register - don't suddenly turn formal.

        GROUPING - AT MOST TWO FIELDS PER QUESTION
        You are told CURRENT_QUESTION_GROUP: one or two related fields to ask about right now. If it has two,
        combine them into ONE short natural question only because they're genuinely the same topic a person
        would answer together (address+city, brand+model, salary+position, service+deadline). Never mix
        unrelated topics into one question. If the group has one field, ask about just that one. Ask exactly
        one question - never a list, never multiple sentences each posing a separate question.

        ALREADY_KNOWN lists what has already been established this conversation - never ask about any of it.
        MERGED_FIELD_MAP is the only preprocessed field data from documents/profile/memory that you may use.
        Never ask about a field already present there with confidence >= 0.75.

        Extraction rules (all optional, use only what genuinely applies):
        - If USER_REQUEST already states the value of ANY field listed in ALL_ELIGIBLE_FIELDS (not just the
          current group), return it in "extracted" - lightly normalized, never guessed or invented.
        - MERGED_FIELD_MAP lists facts already established before the interview, each keyed by template
          field id with value, confidence, and source. Treat it exactly like USER_REQUEST: if it states the value of ANY
          field in ALL_ELIGIBLE_FIELDS, return it in "extracted" and never ask about that field again. This
          is the single highest-value thing you can do - a user who uploaded documents should barely be
          asked anything the documents already answer.
        - If CURRENT_MESSAGE (the user's answer to the question you asked last turn) states the value of a
          field in CURRENT_QUESTION_GROUP, return it in "extracted" too. Never use CURRENT_MESSAGE to fill a
          field outside CURRENT_QUESTION_GROUP, even if it superficially resembles one - an answer about one
          topic must never be reused for a different field just because both mention a date or a place.
        - If everything in CURRENT_QUESTION_GROUP is already covered by "extracted", set "question" to null.

        "question" MUST be written strictly in the language given by LANGUAGE (ru = Russian, uz = Uzbek,
        en = English), regardless of what language the field labels or the user's message are in.

        Output ONLY valid JSON, no Markdown, no explanations, matching exactly:
        {"question":"<one natural question, or null>","extracted":{"<fieldId>":"<value>"}}

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
            SUGGESTED_ACK: {context.SuggestedAcknowledgement ?? "(none - this is the first question)"}
            USER_REQUEST: {context.UserRequest ?? "(not provided - template was picked manually)"}
            MERGED_FIELD_MAP:
            {context.MergedFields.ToPromptContext() ?? "(no preprocessed fields)"}
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
