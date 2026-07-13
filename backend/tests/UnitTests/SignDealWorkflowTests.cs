using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The architectural rule: either party may sign first, one party's
/// signature must never overwrite or be inferred from the other's, and the
/// deal only reaches <see cref="DealStatus.FullySigned"/> once both
/// <see cref="Deal.FirstPartySignedAt"/> and <see cref="Deal.SecondPartySignedAt"/>
/// are set.
/// </summary>
public sealed class SignDealWorkflowTests
{
    private static Deal GeneratedDeal() => new()
    {
        Id = Guid.NewGuid(),
        TemplateKey = "vehicle-sale",
        GeneratedHtml = "<p>agreement</p>",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
    };

    [Fact]
    public async Task Second_party_signing_first_does_not_fully_sign_the_deal()
    {
        var deal = GeneratedDeal();
        var repo = new DealRepo(deal);

        var success = await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name");

        Assert.True(success);
        Assert.NotNull(deal.SecondPartySignedAt);
        Assert.Null(deal.FirstPartySignedAt);
        Assert.NotEqual(DealStatus.FullySigned, deal.Status);
    }

    [Fact]
    public async Task First_party_signing_first_does_not_fully_sign_the_deal()
    {
        var deal = GeneratedDeal();
        var repo = new DealRepo(deal);

        var success = await new SignDealFirstPartyUseCase(repo).ExecuteAsync(deal.Id, "Seller Name");

        Assert.True(success);
        Assert.NotNull(deal.FirstPartySignedAt);
        Assert.Null(deal.SecondPartySignedAt);
        Assert.NotEqual(DealStatus.FullySigned, deal.Status);
    }

    [Fact]
    public async Task Deal_becomes_fully_signed_only_after_both_parties_sign_second_then_first()
    {
        var deal = GeneratedDeal();
        var repo = new DealRepo(deal);

        await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name");
        await new SignDealFirstPartyUseCase(repo).ExecuteAsync(deal.Id, "Seller Name");

        Assert.NotNull(deal.FirstPartySignedAt);
        Assert.NotNull(deal.SecondPartySignedAt);
        Assert.Equal(DealStatus.FullySigned, deal.Status);
    }

    [Fact]
    public async Task Deal_becomes_fully_signed_only_after_both_parties_sign_first_then_second()
    {
        var deal = GeneratedDeal();
        var repo = new DealRepo(deal);

        await new SignDealFirstPartyUseCase(repo).ExecuteAsync(deal.Id, "Seller Name");
        await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name");

        Assert.NotNull(deal.FirstPartySignedAt);
        Assert.NotNull(deal.SecondPartySignedAt);
        Assert.Equal(DealStatus.FullySigned, deal.Status);
    }

    [Fact]
    public async Task Repeated_second_party_sign_calls_never_overwrite_the_first_signature_timestamp()
    {
        var deal = GeneratedDeal();
        var repo = new DealRepo(deal);

        await new SignDealFirstPartyUseCase(repo).ExecuteAsync(deal.Id, "Seller Name");
        var firstSignedAt = deal.FirstPartySignedAt;

        // The second party signing (even repeatedly) must never touch the
        // first party's timestamp or name.
        await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name");
        await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name Again");

        Assert.Equal(firstSignedAt, deal.FirstPartySignedAt);
        Assert.Equal("Seller Name", deal.FirstPartyName);
    }

    [Fact]
    public async Task Signing_before_generation_fails()
    {
        var deal = new Deal
        {
            Id = Guid.NewGuid(),
            TemplateKey = "vehicle-sale",
            GeneratedHtml = null,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        var repo = new DealRepo(deal);

        Assert.False(await new SignDealFirstPartyUseCase(repo).ExecuteAsync(deal.Id, "Seller Name"));
        Assert.False(await new SignDealSecondPartyUseCase(repo).ExecuteAsync(deal.Id, "Buyer Name"));
    }

    private sealed class DealRepo(Deal deal) : IDealRepository
    {
        public Task<Deal> AddAsync(Deal newDeal, CancellationToken cancellationToken = default) => Task.FromResult(newDeal);

        public Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
            Task.FromResult(id == deal.Id ? deal : null);

        public Task UpdateAsync(Deal updatedDeal, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }
}
