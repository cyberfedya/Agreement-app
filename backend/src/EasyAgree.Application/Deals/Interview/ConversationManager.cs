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
                askedQuestions, dismissedDocumentSuggestions, cancellationToken);
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
                        askedQuestions, dismissedDocumentSuggestions, cancellationToken);

            case ConversationIntent.DontKnow:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.DontKnowNotice(language)} {bareQuestionText}");

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
                    askedQuestions, dismissedDocumentSuggestions, cancellationToken);
        }
    }
}
