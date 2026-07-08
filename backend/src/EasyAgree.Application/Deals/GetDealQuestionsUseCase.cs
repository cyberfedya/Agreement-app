using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Contracts.Templates;

namespace EasyAgree.Application.Deals;

public sealed class GetDealQuestionsUseCase(IDealRepository dealRepository, GetQuestionsUseCase getQuestions)
{
    public async Task<IReadOnlyList<QuestionDto>?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        return deal is null ? null : await getQuestions.ExecuteAsync(deal.TemplateKey, cancellationToken);
    }
}
