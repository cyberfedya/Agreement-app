using EasyAgree.Domain.Entities;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Orchestrates one interview turn: classify fields, pick the next group
/// in priority order, ask the question generator for a natural combined
/// question, and fold in whatever it could extract. Deciding whether
/// enough information exists is entirely deterministic (no required
/// field left to ask) - the model is only ever asked to phrase a
/// question and extract values, never to judge readiness, which is what
/// previously let it end the interview while real fields were still
/// unanswered.
/// </summary>
public sealed class InterviewPlanner(QuestionGenerator questionGenerator)
{
    /// <summary>
    /// Caps how many times a single HTTP turn can loop back to the model
    /// when a whole question group gets satisfied purely by extraction
    /// (e.g. a rich opening request already answers several groups at
    /// once) - bounds latency/cost while still letting the interview
    /// "catch up" within one turn instead of asking a redundant question.
    /// </summary>
    private const int MaxPlanningIterations = 4;

    public async Task<InterviewPlanResult> ExecuteAsync(
        string templateTitle,
        string language,
        string? userRequest,
        string? currentMessage,
        MergedFieldCollection mergedFields,
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        Dictionary<int, string> answers,
        CancellationToken cancellationToken)
    {
        var classified = FieldEligibilityEngine.Classify(fields, labels);
        var isFirstTurn = currentMessage is null;

        for (var iteration = 0; iteration < MaxPlanningIterations; iteration++)
        {
            var askable = Askable(classified, answers);
            if (askable.Count == 0)
                return InterviewPlanResult.Ready(ClosingPhrases.Pick(language));

            var ordered = QuestionPriorityEngine.Order(askable);
            var group = QuestionGroupingEngine.BuildGroups(ordered)[0];

            // Nothing to acknowledge on the very first question - the user
            // hasn't answered anything yet, only stated their request.
            var acknowledgement = isFirstTurn ? null : AcknowledgementPhrases.Pick(language, answers.Count);
            var context = new InterviewContext(
                templateTitle, language, userRequest, currentMessage, group, answers, ordered, acknowledgement, mergedFields);
            var generated = await questionGenerator.GenerateAsync(context, cancellationToken);
            if (string.IsNullOrWhiteSpace(generated.Question) && generated.Extracted.Count == 0)
            {
                // A blank result usually means a transient failure (timeout,
                // unparseable JSON) rather than "everything got extracted" -
                // one retry clears most of those before we resort to a
                // generic fallback question.
                generated = await questionGenerator.GenerateAsync(context, cancellationToken);
            }

            // USER_REQUEST is only meaningful on the first turn, but
            // the merged field map is reliable structured data (not raw OCR)
            // regardless of when documents were uploaded, so it's allowed
            // to fill any eligible field on every turn.
            var allowedExtractionIds = group.Select(f => f.FieldId).ToHashSet();
            if (isFirstTurn || mergedFields.Fields.Count > 0)
                allowedExtractionIds.UnionWith(ordered.Select(f => f.FieldId));

            foreach (var (fieldId, value) in generated.Extracted)
            {
                if (allowedExtractionIds.Contains(fieldId) && !string.IsNullOrWhiteSpace(value) && !answers.ContainsKey(fieldId))
                    answers[fieldId] = value;
            }

            var firstMissing = group.FirstOrDefault(f => !answers.ContainsKey(f.FieldId));
            if (firstMissing is not null)
            {
                var question = string.IsNullOrWhiteSpace(generated.Question)
                    ? ConversationReplies.GenericFallbackQuestion(language)
                    : generated.Question!;
                return InterviewPlanResult.NeedMoreInfo(firstMissing.FieldId, question);
            }

            // The whole group got covered by extraction alone - loop to the
            // next group instead of surfacing a now-redundant question.
        }

        // Iteration cap hit (rare) - fall back to a plain, deterministic
        // question for whatever is still missing rather than calling the
        // model again.
        var remaining = Askable(classified, answers);
        if (remaining.Count == 0)
            return InterviewPlanResult.Ready(ClosingPhrases.Pick(language));

        var next = QuestionPriorityEngine.Order(remaining)[0];
        return InterviewPlanResult.NeedMoreInfo(next.FieldId, next.Label);
    }

    private static List<ClassifiedField> Askable(IReadOnlyList<ClassifiedField> classified, Dictionary<int, string> answers) =>
        classified
            .Where(f => f.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .Where(f => !answers.ContainsKey(f.FieldId))
            .ToList();
}
