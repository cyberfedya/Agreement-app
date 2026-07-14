using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class DealFieldStateWorkflowTests
{
    [Fact]
    public async Task Proposed_second_party_change_marks_one_field_disputed_and_requires_review()
    {
        var dealId = Guid.NewGuid();
        var deal = new Deal
        {
            Id = dealId,
            TemplateKey = "vehicle-sale",
            PartyResponsesJson = DealPartyResponseSerializer.Serialize([
                new DealPartyResponse(
                    DealPartyResponseTypes.ProposedChange,
                    32,
                    "12000 USD",
                    "Buyer asked to change the price",
                    "second",
                    DateTime.UtcNow),
            ]),
            InviteStatus = InviteStatus.ChangeRequested,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        var template = Template("vehicle-sale", (21, "vehicle make"), (32, "sale price"));
        var useCase = new GetDealFieldStatesUseCase(
            new DealRepo(deal),
            new TemplateRepo(template),
            new DocumentRepo([]),
            new ProfileRepo(),
            new PartyProfileResolver(new PartyRoleClassifier(new UnusedAiChatClient())));

        var result = await useCase.ExecuteAsync(dealId);

        Assert.NotNull(result);
        Assert.Equal(DealWorkflowStatus.LegalReviewRequired, result.WorkflowStatus);
        var disputed = Assert.Single(result.Fields, field => field.Dispute);
        Assert.Equal(32, disputed.FieldId);
        Assert.Equal("12000 USD", disputed.Value);
        Assert.Equal("DISPUTED", disputed.ConfirmationStatus);
    }

    [Fact]
    public async Task Missing_required_terms_report_missing_mandatory_status()
    {
        var dealId = Guid.NewGuid();
        var deal = new Deal
        {
            Id = dealId,
            TemplateKey = "vehicle-sale",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        var template = Template("vehicle-sale", (32, "sale price"));
        var useCase = new GetDealFieldStatesUseCase(
            new DealRepo(deal),
            new TemplateRepo(template),
            new DocumentRepo([]),
            new ProfileRepo(),
            new PartyProfileResolver(new PartyRoleClassifier(new UnusedAiChatClient())));

        var result = await useCase.ExecuteAsync(dealId);

        Assert.NotNull(result);
        Assert.Equal(DealWorkflowStatus.MissingMandatoryTerms, result.WorkflowStatus);
        Assert.Contains(result.Fields, field => field.FieldId == 32 && field.Status == "MISSING");
    }

    private static AgreementTemplate Template(string key, params (int FieldId, string Label)[] fields) => new()
    {
        Id = Guid.NewGuid(),
        Domain = "test",
        Key = key,
        HtmlTemplate = string.Join("", fields.Select(field => $"<span>{{#{field.FieldId}}}{field.Label}</span>")),
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        Fields = fields.Select(field => new AgreementTemplateField
        {
            Id = Guid.NewGuid(),
            AgreementTemplateId = Guid.NewGuid(),
            FieldId = field.FieldId,
            Mode = AgreementFieldMode.Required,
        }).ToList(),
    };

    private sealed class DealRepo(Deal deal) : IDealRepository
    {
        public Task<Deal> AddAsync(Deal newDeal, CancellationToken cancellationToken = default) => Task.FromResult(newDeal);

        public Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
            Task.FromResult(id == deal.Id ? deal : null);

        public Task UpdateAsync(Deal updatedDeal, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }

    private sealed class TemplateRepo(AgreementTemplate template) : IAgreementTemplateRepository
    {
        public Task<IReadOnlyList<AgreementTemplate>> GetActiveAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<AgreementTemplate>>([template]);

        public Task<AgreementTemplate?> GetByKeyAsync(string key, CancellationToken cancellationToken = default) =>
            Task.FromResult(key == template.Key ? template : null);
    }

    private sealed class ProfileRepo : IUserProfileRepository
    {
        public Task<UserProfile?> GetAsync(string id, CancellationToken cancellationToken = default) =>
            Task.FromResult<UserProfile?>(null);

        public Task<UserProfile> UpsertAsync(UserProfile profile, CancellationToken cancellationToken = default) =>
            Task.FromResult(profile);

        public Task DeleteAsync(string id, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }

    private sealed class UnusedAiChatClient : IAiChatClient
    {
        public Task<string> CompleteAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Not expected to be called when neither party has a profile.");
    }

    private sealed class DocumentRepo(List<UploadedDocument> documents) : IUploadedDocumentRepository
    {
        public Task<UploadedDocument> AddAsync(UploadedDocument document, CancellationToken cancellationToken = default) =>
            Task.FromResult(document);

        public Task<UploadedDocument?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
            Task.FromResult(documents.FirstOrDefault(document => document.Id == id));

        public Task<List<UploadedDocument>> GetByDealIdAsync(Guid dealId, CancellationToken cancellationToken = default) =>
            Task.FromResult(documents);

        public Task UpdateAsync(UploadedDocument document, CancellationToken cancellationToken = default) => Task.CompletedTask;

        public Task DeleteAsync(UploadedDocument document, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }
}
