using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Validation;

namespace EasyAgree.Application.Risk;

public sealed class GetDealRiskAssessmentUseCase(
    IDealRepository dealRepository,
    IUploadedDocumentRepository documentRepository,
    GetDealAgreementValidationUseCase validationUseCase,
    GetDealQualityUseCase qualityUseCase)
{
    public async Task<AgreementRiskAssessment?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null) return null;
        var validation = await validationUseCase.ExecuteAsync(dealId, cancellationToken);
        var quality = await qualityUseCase.ExecuteAsync(dealId, cancellationToken);
        if (validation is null || quality is null) return null;
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        return AgreementRiskEngine.Assess(validation, quality, DocumentConflictEngine.Detect(documents),
            !string.IsNullOrWhiteSpace(deal.GeneratedHtml), deal.SecondPartySignedAt is not null);
    }
}
