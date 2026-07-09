using EasyAgree.Domain.Enums;

namespace EasyAgree.Domain.Entities;

/// <summary>
/// A single agreement-creation session: created once the user's free-form
/// request (or a manually picked template) has been matched to an
/// <see cref="AgreementTemplate"/>, and completed once it's generated.
/// </summary>
public class Deal
{
    public Guid Id { get; set; }

    public required string TemplateKey { get; set; }

    /// <summary>The free-form text that produced this deal, if any (null when created from a direct template pick).</summary>
    public string? RequestText { get; set; }

    public DealStatus Status { get; set; } = DealStatus.Draft;

    /// <summary>
    /// Answers collected so far, keyed by field id, serialized as JSON
    /// (<c>{"3":"answer text",...}</c>). Persisted here — not just
    /// client-side — because the interview planner (<c>GetNextQuestionUseCase</c>)
    /// needs to know what's already known on every turn, including after
    /// the app is killed and reopened mid-interview.
    /// </summary>
    public string? AnswersJson { get; set; }

    public string? GeneratedHtml { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}
