using System.Text.Json;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals.Interview;

public sealed record GeneratedQuestion(string? Question, IReadOnlyDictionary<int, string> Extracted);

/// <summary>
/// Turns one current field group into either extracted values or one short question.
/// Field ordering and eligibility stay deterministic upstream; the model only maps
/// focused document hints and phrases the next prompt.
/// </summary>
public sealed class QuestionGenerator(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You generate the next intake question for a legal agreement app.

        STYLE
        Be short and direct. Ask one compact question only.
        No praise, no progress phrases, no preambles, no "almost done".
        Prefer 5-10 words. Absolute maximum: 12 words.
        Use simple language matching LANGUAGE. Think like a notary talking
        to a client, not like a database.
        One topic per question: never combine time with place, price with
        anything else, or any two unrelated things in one question.
        Never ask about deep technical specifications (engine power or
        displacement, weight, seating, emissions class, fuel) - those come
        only from uploaded documents. VIN, engine number, body number and
        chassis number ARE allowed when they appear in
        CURRENT_QUESTION_GROUP: ask them together as one short question
        ("Какой VIN, номер двигателя, кузова и шасси?").

        Do not use bureaucratic verbs: "Specify", "Provide", "Enter", "Input",
        "Укажите", "Введите", "Заполните", "Предоставьте".
        Prefer natural short questions:
        ru: "Какая марка и модель?", "Какой VIN?", "Какая цена?", "Когда передача?"
        en: "What make and model?", "What VIN?", "What price?", "When is transfer?"

        If document hints clearly suggest the current value but need confirmation,
        ask a short yes/no question: "Chevrolet Nexia 3, 2019 год — верно?"

        GROUPING
        CURRENT_QUESTION_GROUP contains one or more related fields (almost always one - a
        multi-field group only happens for a documented combined-question set like
        VIN/engine/body/chassis number). Ask only about those fields.
        If the group has more than one field, combine them into one short question naming all of them.
        Never ask about ALREADY_KNOWN fields. Never mention known neighboring fields unless needed to disambiguate.
        Never ask a list. Never ask two sentences.

        EXTRACTION
        - USER_REQUEST may fill any field in ALL_ELIGIBLE_FIELDS on the first turn only.
        - DOCUMENT_FIELD_HINTS may fill fields in CURRENT_QUESTION_GROUP only.
        - CURRENT_MESSAGE may fill fields in CURRENT_QUESTION_GROUP only.
        - Never force-fit document values. Be precise:
          vehicle_make, model, year, vin, body_number, chassis_number, engine_number,
          plate_number and issued_date are different fields.
          A date is not a make/model. Chassis is not year. Model is not VIN/body/chassis.
          Different issuing authorities are different fields; do not copy one into another.
          When CURRENT_QUESTION_GROUP has several number-only technical identifiers
          (VIN, engine, body/kuzov, chassis), match each answered value to the concept
          it actually describes, not to the order it was typed in - a mis-attributed
          value (e.g. writing the VIN under the engine number's fieldId) leaves the
          real field empty and makes the interview ask about it again right after.
          Example: fields "23: engine number", "24: body number", "25: chassis
          number", "37: VIN" with answer "VIN JT2SV22E8P0123456, двигатель AB1234,
          кузов CD5678, шасси EF9012" extracts
          {"37":"JT2SV22E8P0123456","23":"AB1234","24":"CD5678","25":"EF9012"}.
        - If everything in CURRENT_QUESTION_GROUP is covered, set "question" to null.
        - If something is still missing, ask the shortest possible question for the missing field(s).

        "question" MUST be written in LANGUAGE: ru = Russian, uz = Uzbek, en = English.

        Output ONLY valid JSON:
        {"question":"<one short question, or null>","extracted":{"<fieldId>":"<value>"}}
        Omit "extracted" or use {} when nothing new can be extracted.
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
            DOCUMENT_FIELD_HINTS:
            {context.DocumentHints.ToPromptContext() ?? "(no document fields extracted)"}
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
