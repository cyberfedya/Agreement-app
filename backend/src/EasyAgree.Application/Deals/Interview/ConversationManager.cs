using EasyAgree.Domain.Entities;

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
        string templateTitle,
        string language,
        string? userRequest,
        string? documentContext,
        int? answeredFieldId,
        string? answerText,
        string? currentQuestionText,
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        Dictionary<int, string> answers,
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
                templateTitle, language, userRequest, answerText, documentContext, fields, labels, answers, cancellationToken);
        }

        var intent = await intentClassifier.ClassifyAsync(currentQuestionText, answerText, cancellationToken);

        switch (intent)
        {
            case ConversationIntent.Answer:
                // Record the literal answer verbatim before planning -
                // exactly as the pre-classification code always did. The
                // planner only ever deals with what's left to ask; it
                // never needs to see the field that was just filled.
                answers[fieldId] = answerText;
                return await interviewPlanner.ExecuteAsync(
                        templateTitle, language, userRequest, answerText, documentContext, fields, labels, answers, cancellationToken);

            case ConversationIntent.Question:
            case ConversationIntent.Help:
                var explanation = await sideAnswerer.AnswerAsync(currentQuestionText, answerText, language, cancellationToken);
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{explanation} {ConversationReplies.Resume(language)} {currentQuestionText}");

            case ConversationIntent.OffTopic:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.OffTopicRedirect(language)} {currentQuestionText}");

            case ConversationIntent.ChangeTopic:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.ChangeTopicNotice(language)} {currentQuestionText}");

            case ConversationIntent.Cancel:
                return InterviewPlanResult.NeedMoreInfo(
                    fieldId, $"{ConversationReplies.CancelNotice(language)} {currentQuestionText}");

            default:
                return await interviewPlanner.ExecuteAsync(
                    templateTitle, language, userRequest, answerText, documentContext, fields, labels, answers, cancellationToken);
        }
    }
}
