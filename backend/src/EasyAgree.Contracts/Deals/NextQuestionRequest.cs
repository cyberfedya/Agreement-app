namespace EasyAgree.Contracts.Deals;

/// <summary>
/// The answer to the field the previous call asked about, if any (omit
/// all three on the very first call for a deal). <see cref="Question"/> is
/// the exact question text the client was just shown - used to classify
/// whether <see cref="Answer"/> actually answers it, or is a side remark
/// (a question, off-topic, wanting to cancel, etc) that must not advance
/// the interview.
/// </summary>
public sealed record NextQuestionRequest(int? FieldId, string? Answer, string? Question);
