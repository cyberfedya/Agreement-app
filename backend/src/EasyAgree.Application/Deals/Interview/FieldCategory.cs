namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// How the interview planner treats a template field. Only the three
/// "Required*" categories are ever proactively asked about, in that
/// priority order; <see cref="NeverAsk"/> covers everything that's
/// system-generated, already known from the creator's profile, belongs
/// to the second party (filled after QR), or is a legal default the
/// backend inserts on its own.
/// </summary>
public enum FieldCategory
{
    RequiredObject,
    RequiredCommercial,
    RequiredTime,
    NeverAsk,

    /// <summary>
    /// Technical characteristics an ordinary person does not know from
    /// memory (engine number, chassis number, weight, engine power, ...).
    /// Never asked in the interview; filled exclusively from uploaded
    /// documents, and left blank - without blocking generation - when no
    /// document was provided.
    /// </summary>
    DocumentOnly,
}
