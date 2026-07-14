using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Templates;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The architectural rule: once the second party accepts the invite and
/// their profile is linked via <see cref="Deal.SecondPartyProfileId"/>,
/// regenerating the agreement must render their real data into the buyer
/// fields - never a blank placeholder. <see cref="PartyRoleClassifier"/> is
/// LLM-backed and not guaranteed to answer identically across calls, so
/// <see cref="GenerateFromDealUseCase"/> must reuse the role persisted from
/// the first generate call instead of re-classifying on every regenerate -
/// otherwise a non-deterministic classifier flip could silently swap which
/// role's keywords the second party's profile gets matched against.
/// </summary>
public sealed class GenerateFromDealSecondPartyRenderingTests
{
    private static readonly Guid DealId = Guid.NewGuid();

    private static readonly AgreementTemplate Template = new()
    {
        Id = Guid.NewGuid(),
        Domain = "vehicle",
        Key = "vehicle-sale",
        HtmlTemplate =
            "<span>{#9}Сотувчининг манзили</span><span>{#10}Сотувчининг Ф.И.О</span><span>{#11}Сотувчининг паспорт серияси</span>" +
            "<span>{#15}Сотиб олувчининг манзили</span><span>{#16}Сотиб олувчининг Ф.И.О</span><span>{#17}Сотиб олувчининг паспорт серияси</span>",
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        Fields =
        [
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 9, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 10, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 11, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 15, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 16, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 17, Mode = AgreementFieldMode.Required },
        ],
    };

    private static Deal NewDeal() => new()
    {
        Id = DealId,
        TemplateKey = Template.Key,
        RequestText = "Продаю свою машину",
        ProfileId = "seller-profile",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
    };

    [Fact]
    public async Task Second_party_profile_renders_after_accept_even_if_the_classifier_would_answer_differently_on_replay()
    {
        var deal = NewDeal();
        var dealRepo = new DealRepo(deal);
        var profileRepo = new ProfileRepo(
            new UserProfile
            {
                Id = "seller-profile",
                FullName = "Продавцов Продавец Продавцович",
                PassportNumber = "AC7654321",
                Address = "г. Самарканд, ул. Образцовая, 5",
            },
            new UserProfile
            {
                Id = "buyer-profile",
                FullName = "Покупателев Покупатель Покупателевич",
                PassportNumber = "AD1234567",
                Address = "г. Ташкент, ул. Примерная, 1",
            });
        // Always says "A" (creator is role A / seller) - a deterministic
        // classifier only used to seed the first call's persisted role.
        var aiClient = new FlippingAiChatClient(firstAnswer: "A", subsequentAnswer: "B");
        var useCase = BuildUseCase(dealRepo, profileRepo, aiClient);

        // Call 1: pre-accept, no second-party profile linked yet.
        var first = await useCase.ExecuteAsync(DealId, new Dictionary<int, string>());
        Assert.NotNull(first.Html);
        Assert.Equal(1, aiClient.CallCount);
        Assert.Equal("seller", deal.FirstPartyRole);
        Assert.Equal("buyer", deal.ExpectedSecondPartyRole);

        // Second party accepts the invite.
        deal.SecondPartyProfileId = "buyer-profile";
        deal.AcceptedAt = DateTime.UtcNow;

        // Call 2: post-accept regenerate. If the classifier were invoked
        // again and flipped its answer (as FlippingAiChatClient does after
        // the first call), the buyer profile would get matched against the
        // seller's keywords and fail to render.
        var second = await useCase.ExecuteAsync(DealId, new Dictionary<int, string>());

        Assert.NotNull(second.Html);
        Assert.Equal(1, aiClient.CallCount); // classifier not called again - persisted role reused

        // Full name, passport and address must all render from
        // SecondPartyProfile, exactly like FirstPartyProfile's own fields -
        // not just the name.
        Assert.Contains("Покупателев Покупатель Покупателевич", second.Html);
        Assert.Contains("AD1234567", second.Html);
        Assert.Contains("г. Ташкент, ул. Примерная, 1", second.Html);
        Assert.DoesNotContain("____________", second.Html);

        // Seller's own fields must be unaffected.
        Assert.Contains("Продавцов Продавец Продавцович", second.Html);
    }

    /// <summary>
    /// Signing (<see cref="SignDealSecondPartyUseCase"/>) never touches
    /// <see cref="Deal.GeneratedHtml"/> - the rendered buyer data from the
    /// post-accept regenerate must still be there afterwards, not reset to
    /// placeholders by the sign step.
    /// </summary>
    [Fact]
    public async Task Second_party_data_survives_signing()
    {
        var deal = NewDeal();
        var dealRepo = new DealRepo(deal);
        var profileRepo = new ProfileRepo(
            new UserProfile { Id = "seller-profile", FullName = "Продавцов Продавец Продавцович" },
            new UserProfile { Id = "buyer-profile", FullName = "Покупателев Покупатель Покупателевич", PassportNumber = "AD1234567" });
        var useCase = BuildUseCase(dealRepo, profileRepo, new FlippingAiChatClient(firstAnswer: "A", subsequentAnswer: "A"));

        await useCase.ExecuteAsync(DealId, new Dictionary<int, string>());
        deal.SecondPartyProfileId = "buyer-profile";
        deal.AcceptedAt = DateTime.UtcNow;
        await useCase.ExecuteAsync(DealId, new Dictionary<int, string>());

        Assert.Contains("Покупателев Покупатель Покупателевич", deal.GeneratedHtml);

        await new SignDealSecondPartyUseCase(dealRepo).ExecuteAsync(DealId, "Покупателев Покупатель Покупателевич");

        Assert.Contains("Покупателев Покупатель Покупателевич", deal.GeneratedHtml);
        Assert.Contains("AD1234567", deal.GeneratedHtml);
    }

    private static GenerateFromDealUseCase BuildUseCase(DealRepo dealRepo, ProfileRepo profileRepo, IAiChatClient aiClient) =>
        new(dealRepo, new TemplateRepo(), profileRepo, new DocumentRepo(), new PartyProfileResolver(new PartyRoleClassifier(aiClient)),
            new GenerateAgreementUseCase(new TemplateRepo()));

    private sealed class FlippingAiChatClient(string firstAnswer, string subsequentAnswer) : IAiChatClient
    {
        public int CallCount { get; private set; }

        public Task<string> CompleteAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default)
        {
            CallCount++;
            return Task.FromResult(CallCount == 1 ? firstAnswer : subsequentAnswer);
        }
    }

    private sealed class DealRepo(Deal deal) : IDealRepository
    {
        public Task<Deal> AddAsync(Deal newDeal, CancellationToken cancellationToken = default) => Task.FromResult(newDeal);

        public Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
            Task.FromResult(id == deal.Id ? deal : null);

        public Task UpdateAsync(Deal updatedDeal, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }

    private sealed class TemplateRepo : IAgreementTemplateRepository
    {
        public Task<IReadOnlyList<AgreementTemplate>> GetActiveAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<AgreementTemplate>>([Template]);

        public Task<AgreementTemplate?> GetByKeyAsync(string key, CancellationToken cancellationToken = default) =>
            Task.FromResult(key == Template.Key ? Template : null);
    }

    private sealed class ProfileRepo(params UserProfile[] profiles) : IUserProfileRepository
    {
        public Task<UserProfile?> GetAsync(string id, CancellationToken cancellationToken = default) =>
            Task.FromResult(profiles.FirstOrDefault(p => p.Id == id));

        public Task<UserProfile> UpsertAsync(UserProfile profile, CancellationToken cancellationToken = default) =>
            Task.FromResult(profile);

        public Task DeleteAsync(string id, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }

    private sealed class DocumentRepo : IUploadedDocumentRepository
    {
        public Task<UploadedDocument> AddAsync(UploadedDocument document, CancellationToken cancellationToken = default) =>
            Task.FromResult(document);

        public Task<UploadedDocument?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
            Task.FromResult<UploadedDocument?>(null);

        public Task<List<UploadedDocument>> GetByDealIdAsync(Guid dealId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new List<UploadedDocument>());

        public Task UpdateAsync(UploadedDocument document, CancellationToken cancellationToken = default) => Task.CompletedTask;

        public Task DeleteAsync(UploadedDocument document, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }
}
