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
    // Deliberately narrow and specific (rather than broad terms like "date"
    // or "city") — those are legitimate answers for plenty of agreements
    // (transfer date, property address). No template field list carries a
    // "source" tag yet (required/ask_current_user/system), so this is a
    // heuristic stand-in for two of the product rules' categories:
    //   1) administrative/notarial metadata about the agreement itself
    //   2) either party's own identity — the creator's is already known,
    //      the second party's comes from the QR-sign flow, so asking here
    //      would violate "DO NOT ask creator/second-party information".
    private static readonly string[] NeverAskKeywords =
    [
        // administrative / notarial metadata
        "нотариал", "нотариус",
        "гувоҳ", "свидетел",
        "муҳр", "печат",
        "рўйхатга ол", "реестр",
        "иш рақами", "номер дела",
        "тузилган сана", "тасдиқланган сана", "дата составления", "дата подписания",
        // seller/buyer identity — belongs to the creator or the second party, never asked here
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

        USER_REQUEST is the user's original free-form request. If USER_REQUEST or CURRENT_MESSAGE already clearly
        states the value of any eligible field, DO NOT ask about that field - return it in "extracted" instead
        (a map of fieldId to the stated value, lightly normalized). Extract only what is explicitly stated;
        never guess or invent values. Example: for the request "I want to sell my apartment", a field
        "description of the property being sold" is already answered ("apartment") - extract it, don't ask.

        Ask only ONE meaningful question at a time. Prefer: 1) the object of the agreement, 2) commercial terms
        (price, payment), 3) dates that materially change the agreement (transfer date, start date, repayment date -
        these are GOOD questions), 4) important identifiers (VIN, cadastral number), 5) optional terms.
        Never ask administrative metadata (where/when the agreement itself was signed, notary office, court,
        registration authority, witnesses, document/case numbers) — ELIGIBLE_FIELDS has already been filtered to
        exclude these; only choose from what's given.

        Questions must sound natural and conversational, not legal or bureaucratic.
        Good: "What price did you agree on?" Bad: "Specify the amount of consideration."
        next_question MUST be written strictly in the language given by LANGUAGE (ru = Russian, uz = Uzbek,
        en = English), regardless of what language the field labels or the user's message are in.

        ELIGIBLE_FIELDS is authoritative and already filtered by the backend. Do not invent fields. Do not ask
        about anything outside ELIGIBLE_FIELDS. Each line is "<fieldId>: <field label>" - next_field, extracted
        keys, and missing_field_keys MUST use that exact fieldId (as a string), never the label text.

        Output ONLY valid JSON, no Markdown, no explanations, matching exactly one of:

        {"status":"need_more_info","next_field":"<fieldId>","next_question":"<natural question text>","reason":"required_field_missing","missing_field_keys":["<fieldId>"],"extracted":{"<fieldId>":"<value>"}}

        {"status":"ready_to_generate","next_field":null,"next_question":null,"reason":"minimum_required_information_collected","missing_field_keys":[],"extracted":{"<fieldId>":"<value>"}}

        Omit "extracted" (or use {}) when nothing new can be extracted.
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

        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        if (answeredFieldId is { } fieldId && !string.IsNullOrWhiteSpace(answerText))
        {
            answers[fieldId] = answerText;
            await SaveAnswersAsync(deal, answers, cancellationToken);
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

        var userMessage = BuildUserMessage(title, language, eligible, labels, answers, answerText, deal.RequestText);
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);
        var parsed = ParseModelOutput(raw);

        // Fold in whatever the model extracted from the request/message, so
        // those fields are never asked about — the core "never ask what's
        // already known" rule.
        var extracted = parsed.Extracted
            .Where(kv => eligibleIds.Contains(kv.Key) && !string.IsNullOrWhiteSpace(kv.Value))
            .ToList();
        if (extracted.Count > 0)
        {
            foreach (var (extractedFieldId, value) in extracted)
            {
                answers[extractedFieldId] = value;
                eligibleIds.Remove(extractedFieldId);
            }
            await SaveAnswersAsync(deal, answers, cancellationToken);
        }

        if (parsed.ReadyToGenerate || eligibleIds.Count == 0)
            return NextQuestionResult.ReadyToGenerate();

        if (parsed.NextFieldId is { } nextFieldId
            && eligibleIds.Contains(nextFieldId)
            && !string.IsNullOrWhiteSpace(parsed.Question))
        {
            return NextQuestionResult.NeedMoreInfo(nextFieldId, parsed.Question);
        }

        // The model's output was unusable or referenced an extracted/unknown
        // field — fall back to the first remaining eligible field's label.
        var fallbackId = eligibleIds.Order().First();
        return NextQuestionResult.NeedMoreInfo(fallbackId, labels[fallbackId]);
    }

    private async Task SaveAnswersAsync(Deal deal, Dictionary<int, string> answers, CancellationToken cancellationToken)
    {
        deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }

    private static string BuildUserMessage(
        string category,
        string language,
        IReadOnlyList<AgreementTemplateField> eligible,
        IReadOnlyDictionary<int, string> labels,
        IReadOnlyDictionary<int, string> answers,
        string? currentMessage,
        string? requestText)
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
            USER_REQUEST: {requestText ?? "(not provided - template was picked manually)"}
            ELIGIBLE_FIELDS:
            {eligibleCatalog}
            EXTRACTED_FIELDS:
            {extractedCatalog}
            CURRENT_MESSAGE: {currentMessage ?? "(interview just started)"}
            """;
    }

    private sealed record ModelOutput(
        bool ReadyToGenerate,
        int? NextFieldId,
        string? Question,
        IReadOnlyDictionary<int, string> Extracted);

    private static ModelOutput ParseModelOutput(string raw)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            var status = root.TryGetProperty("status", out var statusEl) ? statusEl.GetString() : null;

            var extracted = new Dictionary<int, string>();
            if (root.TryGetProperty("extracted", out var extractedEl) && extractedEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in extractedEl.EnumerateObject())
                {
                    if (int.TryParse(prop.Name, out var extractedId) && prop.Value.ValueKind == JsonValueKind.String)
                        extracted[extractedId] = prop.Value.GetString()!;
                }
            }

            int? nextFieldId = null;
            if (root.TryGetProperty("next_field", out var fieldEl)
                && fieldEl.ValueKind == JsonValueKind.String
                && int.TryParse(fieldEl.GetString(), out var parsedFieldId))
            {
                nextFieldId = parsedFieldId;
            }

            var question = root.TryGetProperty("next_question", out var qEl) && qEl.ValueKind == JsonValueKind.String
                ? qEl.GetString()
                : null;

            return new ModelOutput(status == "ready_to_generate", nextFieldId, question, extracted);
        }
        catch (JsonException)
        {
            return new ModelOutput(false, null, null, new Dictionary<int, string>());
        }
    }

    private static bool IsNeverAsk(string label)
    {
        var lower = label.ToLowerInvariant();
        return NeverAskKeywords.Any(lower.Contains);
    }

}
