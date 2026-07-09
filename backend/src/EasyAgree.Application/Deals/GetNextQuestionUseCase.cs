using System.Text.Json;
using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals;

/// <summary>
/// The EasyAgree Interview Planner: decides, one turn at a time, whether
/// another question is needed before the deal's agreement can be
/// generated. Persists answers onto the <see cref="Deal"/> as they come in
/// so state survives across turns (and app restarts).
/// </summary>
public sealed class GetNextQuestionUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IAiChatClient aiChatClient)
{
    private static readonly string[] NeverAskKeywords =
    [
        "нотариал", "нотариус",
        "гувоҳ", "свидетел",
        "муҳр", "печат",
        "рўйхатга ол", "реестр",
        "иш рақами", "номер дела",
        "тузилган сана", "тасдиқланган сана", "дата составления", "дата подписания",
        "сотувчи", "сотиб олувчи", "харидор", "покупател", "продав",
        "паспорт", "ф.и.о",
    ];

    private const string SystemPrompt = """
        You are EasyAgree Interview Planner.
        You are NOT a chatbot. You are an AI component inside EasyAgree.
        Your only responsibility is deciding whether another question must be asked before an agreement draft can be generated.
        Your objective is to collect ONLY the minimum information required to generate a legally meaningful first draft.
        The interview should feel like a natural conversation, not a government questionnaire.
        Never ask unnecessary questions. Never ask questions whose answers are already known (see EXTRACTED_FIELDS).
        Never ask questions that can be generated automatically or that belong to another participant.
        The goal is to reach "ready_to_generate" as quickly as possible.

        Ask only ONE meaningful question at a time. Prefer: 1) the object of the agreement, 2) commercial terms
        (price, payment), 3) dates that materially change the agreement (transfer date, start date, repayment date -
        these are GOOD questions), 4) important identifiers (VIN, cadastral number), 5) optional terms.
        Never ask administrative metadata (where/when the agreement itself was signed, notary office, court,
        registration authority, witnesses, document/case numbers) — ELIGIBLE_FIELDS has already been filtered to
        exclude these; only choose from what's given.

        Questions must sound natural and conversational, not legal or bureaucratic.
        Good: "What price did you agree on?" Bad: "Specify the amount of consideration."

        ELIGIBLE_FIELDS is authoritative and already filtered by the backend. Do not invent fields. Do not ask
        about anything outside ELIGIBLE_FIELDS. Each line is "<fieldId>: <field label>" - next_field and
        missing_field_keys MUST use that exact fieldId (as a string), never the label text.

        Output ONLY valid JSON, no Markdown, no explanations, matching exactly one of:

        {"status":"need_more_info","next_field":"<fieldId>","next_question":"<natural question text>","reason":"required_field_missing","missing_field_keys":["<fieldId>"]}

        {"status":"ready_to_generate","next_field":null,"next_question":null,"reason":"minimum_required_information_collected","missing_field_keys":[]}
        """;

    public async Task<NextQuestionResult> ExecuteAsync(
        Guid dealId,
        int? answeredFieldId,
        string? answerText,
        string language,
        CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return NextQuestionResult.NotFound();

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return NextQuestionResult.NotFound();

        var answers = DeserializeAnswers(deal.AnswersJson);
        if (answeredFieldId is { } fieldId && !string.IsNullOrWhiteSpace(answerText))
        {
            answers[fieldId] = answerText;
            deal.AnswersJson = JsonSerializer.Serialize(answers);
            deal.UpdatedAt = DateTime.UtcNow;
            await dealRepository.UpdateAsync(deal, cancellationToken);
        }

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);

        var eligible = template.Fields
            .Where(f => !answers.ContainsKey(f.FieldId))
            .Where(f => labels.TryGetValue(f.FieldId, out var label) && label.Length > 0)
            .Where(f => !IsNeverAsk(labels[f.FieldId]))
            .OrderBy(f => f.FieldId)
            .ToList();

        if (eligible.Count == 0)
            return NextQuestionResult.ReadyToGenerate();

        var (title, _) = TranslationResolver.Resolve(template.Translations, language);
        var eligibleIds = eligible.Select(f => f.FieldId).ToHashSet();

        var userMessage = BuildUserMessage(title, language, eligible, labels, answers, answerText);
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);

        return ParseResponse(raw, eligibleIds, labels);
    }

    private static string BuildUserMessage(
        string category,
        string language,
        IReadOnlyList<AgreementTemplateField> eligible,
        IReadOnlyDictionary<int, string> labels,
        IReadOnlyDictionary<int, string> answers,
        string? currentMessage)
    {
        var eligibleCatalog = string.Join('\n', eligible.Select(f => $"{f.FieldId}: {labels[f.FieldId]}"));
        var extractedCatalog = answers.Count == 0
            ? "(none yet)"
            : string.Join(
                '\n',
                answers.Select(a =>
                    $"{a.Key}: {(labels.TryGetValue(a.Key, out var label) ? label : a.Key.ToString())} = {a.Value}"));

        return $"""
            CATEGORY: {category}
            LANGUAGE: {language}
            ELIGIBLE_FIELDS:
            {eligibleCatalog}
            EXTRACTED_FIELDS:
            {extractedCatalog}
            CURRENT_MESSAGE: {currentMessage ?? "(interview just started)"}
            """;
    }

    /// <summary>Falls back to the first eligible field if the model's output is unusable or hallucinated.</summary>
    private static NextQuestionResult ParseResponse(
        string raw, IReadOnlySet<int> eligibleIds, IReadOnlyDictionary<int, string> labels)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            var status = root.TryGetProperty("status", out var statusEl) ? statusEl.GetString() : null;

            if (status == "ready_to_generate")
                return NextQuestionResult.ReadyToGenerate();

            if (status == "need_more_info"
                && root.TryGetProperty("next_field", out var fieldEl)
                && int.TryParse(fieldEl.GetString(), out var parsedFieldId)
                && eligibleIds.Contains(parsedFieldId))
            {
                var question = root.TryGetProperty("next_question", out var qEl) ? qEl.GetString() : null;
                if (!string.IsNullOrWhiteSpace(question))
                    return NextQuestionResult.NeedMoreInfo(parsedFieldId, question);
            }
        }
        catch (JsonException)
        {
            // fall through to the deterministic fallback below
        }

        var fallbackId = eligibleIds.Order().First();
        return NextQuestionResult.NeedMoreInfo(fallbackId, labels[fallbackId]);
    }

    private static bool IsNeverAsk(string label)
    {
        var lower = label.ToLowerInvariant();
        return NeverAskKeywords.Any(lower.Contains);
    }

    private static Dictionary<int, string> DeserializeAnswers(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json)?
                .ToDictionary(kv => int.Parse(kv.Key), kv => kv.Value) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }
}
