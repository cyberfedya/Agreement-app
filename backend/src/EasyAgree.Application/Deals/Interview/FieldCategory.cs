namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// How the interview planner treats a template field. Only the three
/// "Required*" categories are ever proactively asked about, in that
/// priority order; <see cref="Optional"/> fields are only filled if the
/// user volunteers them unprompted, and <see cref="NeverAsk"/> covers
/// everything that's system-generated, already known from the creator's
/// profile, belongs to the second party (filled after QR), or is a legal
/// default the backend inserts on its own.
/// </summary>
public enum FieldCategory
{
    RequiredObject,
    RequiredCommercial,
    RequiredTime,
    Optional,
    NeverAsk,
}
