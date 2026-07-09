using EasyAgree.Domain.Entities;

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
                return InterviewPlanResult.Ready();

            var ordered = QuestionPriorityEngine.Order(askable);
            var group = QuestionGroupingEngine.BuildGroups(ordered)[0];

            var context = new InterviewContext(templateTitle, language, userRequest, currentMessage, group, answers, ordered);
            var generated = await questionGenerator.GenerateAsync(context, cancellationToken);

            var allowedExtractionIds = group.Select(f => f.FieldId).ToHashSet();
            if (isFirstTurn)
                allowedExtractionIds.UnionWith(ordered.Select(f => f.FieldId));

            foreach (var (fieldId, value) in generated.Extracted)
            {
                if (allowedExtractionIds.Contains(fieldId) && !string.IsNullOrWhiteSpace(value) && !answers.ContainsKey(fieldId))
                    answers[fieldId] = value;
            }

            var firstMissing = group.FirstOrDefault(f => !answers.ContainsKey(f.FieldId));
            if (firstMissing is not null)
            {
                var question = string.IsNullOrWhiteSpace(generated.Question) ? firstMissing.Label : generated.Question!;
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
            return InterviewPlanResult.Ready();

        var next = QuestionPriorityEngine.Order(remaining)[0];
        return InterviewPlanResult.NeedMoreInfo(next.FieldId, next.Label);
    }

    private static List<ClassifiedField> Askable(IReadOnlyList<ClassifiedField> classified, Dictionary<int, string> answers) =>
        classified
            .Where(f => f.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .Where(f => !answers.ContainsKey(f.FieldId))
            .ToList();
}
