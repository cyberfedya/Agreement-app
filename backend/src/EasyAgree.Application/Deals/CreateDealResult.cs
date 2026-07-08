using EasyAgree.Contracts.Deals;

namespace EasyAgree.Application.Deals;

/// <summary>Discriminated outcome of creating a deal from a request/template pick.</summary>
public sealed class CreateDealResult
{
    public bool IsNoMatch { get; private init; }

    public DealDto? Deal { get; private init; }

    public static CreateDealResult NoMatch() => new() { IsNoMatch = true };

    public static CreateDealResult Success(DealDto deal) => new() { Deal = deal };
}
