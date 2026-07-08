using EasyAgree.Domain.Enums;

namespace EasyAgree.Domain.Entities;

/// <summary>
/// A single agreement-creation session: created once the user's free-form
/// request (or a manually picked template) has been matched to an
/// <see cref="AgreementTemplate"/>, and completed once it's generated.
/// Answers stay client-side until generation — this row is the stable
/// identity ("agreementId") the app flow hangs off, not an answer store.
/// </summary>
public class Deal
{
    public Guid Id { get; set; }

    public required string TemplateKey { get; set; }

    /// <summary>The free-form text that produced this deal, if any (null when created from a direct template pick).</summary>
    public string? RequestText { get; set; }

    public DealStatus Status { get; set; } = DealStatus.Draft;

    public string? GeneratedHtml { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}
