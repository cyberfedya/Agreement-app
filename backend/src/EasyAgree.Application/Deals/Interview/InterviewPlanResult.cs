namespace EasyAgree.Application.Deals.Interview;

public sealed class InterviewPlanResult
{
    public bool IsReady { get; private init; }
    public int? FieldId { get; private init; }
    public string? Question { get; private init; }

    public static InterviewPlanResult Ready(string closingMessage) => new() { IsReady = true, Question = closingMessage };

    public static InterviewPlanResult NeedMoreInfo(int fieldId, string question) =>
        new() { FieldId = fieldId, Question = question };
}
