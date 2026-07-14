using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Validation;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

/// <summary>
/// The architectural rule: a technical vehicle characteristic (emissions
/// class, chassis number, ...) must never count toward "required" in
/// readiness/quality/risk-feeding validation unless it actually has a
/// trusted value - not just because the template marks its
/// <see cref="AgreementFieldMode"/> as Required. Both
/// <see cref="GetDealQualityUseCase"/> and
/// <see cref="GetDealAgreementValidationUseCase"/> must classify fields
/// through <c>FieldEligibilityEngine</c> exactly like the interview does,
/// not read the template's raw field mode directly.
/// </summary>
public sealed class DocumentOnlyReadinessTests
{
    private static readonly Guid DealId = Guid.NewGuid();
    private static readonly AgreementTemplate Template = new()
    {
        Id = Guid.NewGuid(),
        Domain = "vehicle",
        Key = "vehicle-sale",
        HtmlTemplate = "<span>{#10}цена автомобиля</span><span>{#20}экологический класс</span>",
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        Fields =
        [
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 10, Mode = AgreementFieldMode.Required },
            new AgreementTemplateField { Id = Guid.NewGuid(), AgreementTemplateId = Guid.NewGuid(), FieldId = 20, Mode = AgreementFieldMode.Required },
        ],
    };

    private static Deal DealWithPriceAnswered() => new()
    {
        Id = DealId,
        TemplateKey = Template.Key,
        AnswersJson = DealAnswersSerializer.Serialize(new Dictionary<int, string> { [10] = "18000 USD" }),
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
    };

    [Fact]
    public async Task Quality_score_reaches_full_required_completion_without_the_technical_field()
    {
        var useCase = new GetDealQualityUseCase(new DealRepo(DealWithPriceAnswered()), new TemplateRepo(), new DocumentRepo([]));

        var score = await useCase.ExecuteAsync(DealId);

        Assert.NotNull(score);
        Assert.Equal(1.0, score.RequiredCompletion);
        Assert.DoesNotContain(score.Recommendations, r => r.Message.Contains("класс", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task Validation_reports_no_missing_field_issue_for_the_technical_field()
    {
        var useCase = new GetDealAgreementValidationUseCase(new DealRepo(DealWithPriceAnswered()), new TemplateRepo(), new DocumentRepo([]));
        var result = await useCase.ExecuteAsync(DealId);
        Assert.NotNull(result);
        Assert.True(result.IsValid);
        Assert.DoesNotContain(result.Issues, issue => issue.FieldId == 20);
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
