using EasyAgree.Domain.Entities;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Legal;

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
public sealed class InterviewPlanner(QuestionGenerator questionGenerator, LegalKnowledgeEngine? legalKnowledgeEngine = null)
{
    /// <summary>
    /// Caps how many times a single HTTP turn can loop back to the model
    /// when a whole question group gets satisfied purely by extraction
    /// (e.g. a rich opening request already answers several groups at
    /// once) - bounds latency/cost while still letting the interview
    /// "catch up" within one turn instead of asking a redundant question.
    /// </summary>
    private const int MaxPlanningIterations = 20;

    /// <summary>
    /// Hard ceiling on distinct questions asked over the life of one deal -
    /// a simple agreement (e.g. a vehicle sale with no uploaded documents)
    /// must never turn into an interrogation. Counted via
    /// <c>askedQuestions</c> (already persisted per-deal across HTTP turns),
    /// so it holds regardless of how many fields a template declares
    /// required. Repeats of an already-asked question (a side remark that
    /// didn't move the interview on) don't count against it - only genuinely
    /// new questions do. Anything past the cap is left for the same
    /// blank-placeholder treatment <see cref="FieldCategory.DocumentOnly"/>
    /// fields already get - it never blocks generation.
    /// </summary>
    private const int MaxQuestionsPerInterview = 8;

    public async Task<InterviewPlanResult> ExecuteAsync(
        string templateDomain,
        string templateTitle,
        string language,
        string? userRequest,
        string? currentMessage,
        DocumentFieldHintCollection documentHints,
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        Dictionary<int, string> answers,
        Dictionary<string, string> askedQuestions,
        ISet<string> dismissedDocumentSuggestions,
        CancellationToken cancellationToken)
    {
        var enrichedHints = legalKnowledgeEngine is null
            ? documentHints
            : new DocumentFieldHintCollection(legalKnowledgeEngine.Enrich(documentHints.Fields));
        DocumentFieldMapper.ApplyMatches(fields, labels, enrichedHints, answers);

        var classified = FieldEligibilityEngine.Classify(fields, labels);
        var isFirstTurn = currentMessage is null;

        for (var iteration = 0; iteration < MaxPlanningIterations; iteration++)
        {
            var askable = Askable(classified, answers, labels);
            if (askable.Count == 0)
                return InterviewPlanResult.Ready(ClosingPhrases.Pick(language));
            var suggestionCandidates = askable
                .Concat(classified.Where(f => f.Category == FieldCategory.DocumentOnly && !answers.ContainsKey(f.FieldId)))
                .ToList();
            var suggestion = DocumentSuggestionEngine.Evaluate(
                templateDomain, suggestionCandidates, enrichedHints, dismissedDocumentSuggestions);
            if (suggestion is not null)
                return InterviewPlanResult.SuggestDocument(suggestion.DocumentType, suggestion.MatchedFieldCount);

            var ordered = QuestionPriorityEngine.Order(askable);
            var group = QuestionGroupingEngine.BuildGroups(ordered)[0];
            var groupKey = GroupKey(group);
            var isRepeat = askedQuestions.TryGetValue(groupKey, out var previousQuestion);

            if (!isRepeat && askedQuestions.Count >= MaxQuestionsPerInterview)
                return InterviewPlanResult.Ready(ClosingPhrases.Pick(language));

            GeneratedQuestion generated;
            if (isRepeat)
            {
                generated = new GeneratedQuestion(null, new Dictionary<int, string>());
            }
            else
            {
                var acknowledgement = isFirstTurn ? null : AcknowledgementPhrases.Pick(language, answers.Count);
                var context = new InterviewContext(
                    templateTitle, language, userRequest, currentMessage, group, answers, ordered, acknowledgement, enrichedHints);
                generated = await questionGenerator.GenerateAsync(context, cancellationToken);
                if (string.IsNullOrWhiteSpace(generated.Question) && generated.Extracted.Count == 0)
                {
                    generated = await questionGenerator.GenerateAsync(context, cancellationToken);
                }
            }

            var allowedExtractionIds = group.Select(f => f.FieldId).ToHashSet();
            if (isFirstTurn)
                allowedExtractionIds.UnionWith(ordered.Select(f => f.FieldId));

            foreach (var (fieldId, value) in generated.Extracted)
            {
                if (!allowedExtractionIds.Contains(fieldId) || string.IsNullOrWhiteSpace(value) || answers.ContainsKey(fieldId))
                    continue;
                if (labels.TryGetValue(fieldId, out var extractedLabel) && !AnswerShapeValidator.LooksPlausible(extractedLabel, value))
                    continue;

                answers[fieldId] = value;
            }

            var firstMissing = group.FirstOrDefault(f => !answers.ContainsKey(f.FieldId));
            if (firstMissing is not null)
            {
                string question;
                if (isRepeat)
                {
                    question = $"{ConversationReplies.RepeatedQuestionNotice(language)} {previousQuestion}";
                }
                else
                {
                    question = string.IsNullOrWhiteSpace(generated.Question)
                        ? ConversationReplies.GenericFallbackQuestion(language)
                        : generated.Question!;
                    askedQuestions[groupKey] = question;
                }

                return InterviewPlanResult.NeedMoreInfo(firstMissing.FieldId, question);
            }

        }

        var remaining = Askable(classified, answers, labels);
        if (remaining.Count == 0)
            return InterviewPlanResult.Ready(ClosingPhrases.Pick(language));

        var next = QuestionPriorityEngine.Order(remaining)[0];
        return InterviewPlanResult.NeedMoreInfo(next.FieldId, next.Label);
    }

    private static List<ClassifiedField> Askable(
        IReadOnlyList<ClassifiedField> classified,
        Dictionary<int, string> answers,
        IReadOnlyDictionary<int, string> labels) =>
        classified
            .Where(f => f.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .Where(f => !answers.ContainsKey(f.FieldId))
            .Where(f => !FieldDependencyEngine.IsObsolete(f, answers, labels))
            .ToList();

    private static string GroupKey(IEnumerable<ClassifiedField> group) =>
        string.Join(",", group.Select(f => f.FieldId).OrderBy(id => id));
}
