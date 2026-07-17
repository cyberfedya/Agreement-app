using EasyAgree.Domain.Entities;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Entry point for every incoming interview message - classifies intent
/// first, and only ever hands the message to <see cref="InterviewPlanner"/>
/// (which touches the answer set and can advance the interview) when it's
/// actually an answer. Everything else gets a reply that keeps the
/// interview exactly where it was: same field still pending, nothing
/// written to the answer set, current question repeated.
///
/// 4 of the non-answer branches below (Question/Help/OffTopic/ChangeTopic/
/// Cancel) return <see cref="InterviewPlanResult.NeedMoreInfo"/> without a
/// real field group to pass, so its <c>groupFieldIds</c> falls back to just
/// the single echoed field id - a client showing several boxes for a
/// combined question sees that set "shrink" to one for this one reply.
/// Accepted: the client only uses the returned field id to decide whether
/// it's still the same conceptual question (it is), not to resize its box
/// layout on every reply. DontKnow is the exception - it genuinely advances
/// to a new field/group via the planner, see below.
///
/// A multi-field combined answer (one voice/typed blob covering several
/// boxes) is expected to arrive with <c>answeredFieldId</c>/
/// <c>currentQuestionText</c> both null, deliberately taking the fallback
/// branch just below instead of the single-field <see cref="ConversationIntent.Answer"/>
/// branch - the latter would write the whole raw blob verbatim under one
/// field id before <see cref="InterviewPlanner"/> ever gets to re-extract
/// it per-field.
/// </summary>
public sealed class ConversationManager(
    IntentClassifier intentClassifier,
    SideQuestionAnswerer sideAnswerer,
    InterviewPlanner interviewPlanner)
{
    public async Task<InterviewPlanResult> ExecuteAsync(
        string templateDomain,
        string templateTitle,
        string language,
        string? userRequest,
        DocumentFieldHintCollection documentHints,
        int? answeredFieldId,
        string? answerText,
        string? currentQuestionText,
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        Dictionary<int, string> answers,
        Dictionary<string, string> askedQuestions,
        ISet<string> dismissedDocumentSuggestions,
        ISet<int> deferredFieldIds,
        CancellationToken cancellationToken)
    {
        // Nothing to classify against yet - either the very first turn, or
        // the caller didn't send back what it was shown (shouldn't happen
        // from the real client, but degrade to "treat as an answer" rather
        // than fail outright).
        if (answeredFieldId is not { } fieldId || string.IsNullOrWhiteSpace(answerText) || string.IsNullOrWhiteSpace(currentQuestionText))
        {
            if (answeredFieldId is { } fallbackFieldId && !string.IsNullOrWhiteSpace(answerText))
                answers[fallbackFieldId] = answerText;

            return await interviewPlanner.ExecuteAsync(
                templateDomain, templateTitle, language, userRequest, answerText, documentHints, fields, labels, answers,
                askedQuestions, dismissedDocumentSuggestions, deferredFieldIds, cancellationToken);
        }

        var intent = await intentClassifier.ClassifyAsync(currentQuestionText, answerText, cancellationToken);

        // The client always echoes back exactly what it last displayed -
        // if that was itself a notice-wrapped question (e.g. a prior wrong
        // answer), strip the notice back off before wrapping it again, or
        // consecutive wrong answers would stack notices indefinitely.
        var bareQuestionText = ConversationReplies.StripLeadingNotice(language, currentQuestionText);

        switch (intent)
        {
            case ConversationIntent.Answer:
                // Before recording it, check the answer even looks like
                // what this field is asking for (a money/date field with
                // no digits at all, etc.) - catches the case where the
                // intent classifier correctly sees this as an answer, but
                // not to the actual question asked.
                if (labels.TryGetValue(fieldId, out var answeredLabel) &&
                    !AnswerShapeValidator.LooksPlausible(answeredLabel, answerText))
                {
                    return InterviewPlanResult.NeedMoreInfo(
                        fieldId, $"{ConversationReplies.AnswerShapeMismatchNotice(language)} {bareQuestionText}");
                }

                // Record the literal answer verbatim before planning -
                // exactly as the pre-classification code always did. The
                // planner only ever deals with what's left to ask; it
                // never needs to see the field that was just filled.
                answers[fieldId] = answerText;
                return await interviewPlanner.ExecuteAsync(
                        templateDomain, templateTitle, language, userRequest, answerText, documentHints, fields, labels, answers,
                        askedQuestions, dismissedDocumentSuggestions, deferredFieldIds, cancellationToken);

            case ConversationIntent.DontKnow:
                // Move on instead of re-asking: the field is excluded from
                // the askable set (see InterviewPlanner.Askable) but
                // deliberately never written to `answers`, so a document
                // uploaded later can still fill it in normally. Routed
                // through the planner exactly like a real answer so the
                // *next* actual question comes back, just with a brief
                // acknowledgment instead of the field's own wording.
                deferredFieldIds.Add(fieldId);
                var deferredResult = await interviewPlanner.ExecuteAsync(
                    templateDomain, templateTitle, language, userRequest, answerText, documentHints, fields, labels, answers,
                    askedQuestions, dismissedDocumentSuggestions, deferredFieldIds, cancellationToken);
                return WithAcknowledgement(deferredResult, ConversationReplies.DeferredAcknowledgement(language));

            case ConversationIntent.Question:
            case ConversationIntent.Help:
                var explanation = await sideAnswerer.AnswerAsync(bareQuestionText, answerText, language, cancellationToken);
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{explanation} {ConversationReplies.Resume(language)} {bareQuestionText}");

            case ConversationIntent.OffTopic:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.OffTopicRedirect(language)} {bareQuestionText}");

            case ConversationIntent.ChangeTopic:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.ChangeTopicNotice(language)} {bareQuestionText}");

            case ConversationIntent.Cancel:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.CancelNotice(language)} {bareQuestionText}");

            default:
                return await interviewPlanner.ExecuteAsync(
                    templateDomain, templateTitle, language, userRequest, answerText, documentHints, fields, labels, answers,
                    askedQuestions, dismissedDocumentSuggestions, deferredFieldIds, cancellationToken);
        }
    }

    /// <summary>
    /// Prefixes a short acknowledgment onto whatever the planner returned
    /// for the *next* turn - <see cref="InterviewPlanResult"/> has no
    /// settable properties, so this rebuilds one via its own factories
    /// rather than mutating in place. A document suggestion has no question
    /// text to prefix, so it's returned unchanged.
    /// </summary>
    private static InterviewPlanResult WithAcknowledgement(InterviewPlanResult result, string acknowledgement)
    {
        if (result.IsSuggestDocument)
            return result;
        if (result.IsReady)
            return InterviewPlanResult.Ready($"{acknowledgement} {result.Question}");
        return InterviewPlanResult.NeedMoreInfo(result.FieldId!.Value, $"{acknowledgement} {result.Question}", result.GroupFieldIds);
    }
}
