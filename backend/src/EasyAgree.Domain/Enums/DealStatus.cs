namespace EasyAgree.Domain.Enums;

public enum DealStatus
{
    Draft = 0,
    Completed = 1,

    /// <summary>Both FirstPartySignedAt and SecondPartySignedAt are set.</summary>
    FullySigned = 2
}
