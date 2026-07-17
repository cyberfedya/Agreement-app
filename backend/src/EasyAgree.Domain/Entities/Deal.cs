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

    /// <summary>The creator's <see cref="UserProfile.Id"/>, so generation knows whose profile fills the first party.</summary>
    public string? ProfileId { get; set; }

    public DealStatus Status { get; set; } = DealStatus.Draft;

    /// <summary>
    /// Answers collected so far, keyed by field id, serialized as JSON
    /// (<c>{"3":"answer text",...}</c>). Persisted here — not just
    /// client-side — because the interview planner (<c>GetNextQuestionUseCase</c>)
    /// needs to know what's already known on every turn, including after
    /// the app is killed and reopened mid-interview.
    /// </summary>
    public string? AnswersJson { get; set; }

    /// <summary>
    /// Exact wording last used to ask about each still-unanswered field
    /// group so far, keyed by sorted-fieldId group signature (e.g.
    /// <c>"18,19"</c>), serialized as JSON. Lets the interview planner
    /// recognize "I already asked about exactly this" across HTTP turns
    /// and repeat the same wording instead of generating a fresh
    /// rephrasing every time - without this, a field that stays unfilled
    /// for several turns reads to the user as the model looping.
    /// </summary>
    public string? AskedQuestionsJson { get; set; }

    /// <summary>
    /// Document types (<c>DocumentType.ToString()</c>) the user chose
    /// "Continue without document" for, serialized as a JSON array. Once
    /// dismissed, that document's mid-interview upload suggestion never
    /// resurfaces for the rest of this deal.
    /// </summary>
    public string? DismissedDocumentSuggestionsJson { get; set; }

    /// <summary>
    /// Field ids the user said they don't know/can't check right now,
    /// serialized as a JSON array of field ids. Excluded from the
    /// interview's askable set so the same field is never re-asked, but
    /// deliberately never written to <see cref="AnswersJson"/> - a document
    /// uploaded later (or a manual edit) can still fill it in normally.
    /// </summary>
    public string? DeferredFieldIdsJson { get; set; }

    /// <summary>
    /// Pre-interview field map produced from documents/profile/memory,
    /// keyed by template field id and preserving source/confidence so the
    /// intake can be refreshed without losing user-entered answers.
    /// </summary>
    public string? PreprocessedFieldsJson { get; set; }

    /// <summary>
    /// Counterparty responses that must not silently overwrite the
    /// creator's terms: proposed field changes, clarification requests
    /// and decline reasons. Serialized as JSON and resolved explicitly in
    /// review instead of keeping parallel hidden values.
    /// </summary>
    public string? PartyResponsesJson { get; set; }

    public string? GeneratedHtml { get; set; }

    /// <summary>Second party's legal name, set once they complete the QR-sign flow (null until then).</summary>
    public string? SecondPartyName { get; set; }

    public DateTime? SecondPartySignedAt { get; set; }

    /// <summary>Creator's legal name, set once they sign (null until then).</summary>
    public string? FirstPartyName { get; set; }

    /// <summary>
    /// Set independently of <see cref="SecondPartySignedAt"/> - either
    /// party may sign first, and one signature must never overwrite or
    /// imply the other. The deal only becomes fully signed
    /// (<see cref="DealStatus.FullySigned"/>) once both are set.
    /// </summary>
    public DateTime? FirstPartySignedAt { get; set; }

    /// <summary>Where the second party is in accepting the QR invite (never asked/shown to the first party).</summary>
    public InviteStatus InviteStatus { get; set; } = InviteStatus.Pending;

    /// <summary>The creator's role in this deal (e.g. "seller"), resolved once at generation time.</summary>
    public string? FirstPartyRole { get; set; }

    /// <summary>The role the invite expects whoever scans the QR to play (e.g. "buyer").</summary>
    public string? ExpectedSecondPartyRole { get; set; }

    /// <summary>Null for now (no expiry enforced yet) - reserved so the invite endpoint's shape doesn't change later.</summary>
    public DateTime? InviteExpiresAt { get; set; }

    /// <summary>
    /// The second party's own <see cref="UserProfile.Id"/>, set once they
    /// accept the invite - lets generation resolve their identity fields
    /// (name, address, passport) from their real profile instead of only
    /// ever having a bare name captured at sign time.
    /// </summary>
    public string? SecondPartyProfileId { get; set; }

    public DateTime? AcceptedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}
