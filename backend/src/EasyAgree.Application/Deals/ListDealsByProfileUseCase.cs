using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Contracts.Deals;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Feeds the "Deal History" screen: every deal the given profile created or
/// joined as second party, newest first. Deliberately domain-agnostic - a
/// new template category needs no change here, since it only ever reads
/// <see cref="AgreementTemplate.Domain"/> off whatever template the deal
/// points to.
/// </summary>
public sealed class ListDealsByProfileUseCase(
    IDealRepository dealRepository, IAgreementTemplateRepository templateRepository)
{
    public async Task<DealHistoryPageDto> ExecuteAsync(
        string profileId, int page, int pageSize, string language, CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var (deals, totalCount) = await dealRepository.GetByProfileIdAsync(
            profileId, (page - 1) * pageSize, pageSize, cancellationToken);

        // The template catalog is small and already loaded whole elsewhere
        // (CreateDealUseCase's classifier) - reusing that here avoids a
        // per-deal lookup for what's normally a one-page result set.
        var templates = await templateRepository.GetActiveAsync(cancellationToken);
        var templatesByKey = templates.ToDictionary(t => t.Key);

        var items = deals.Select(deal =>
        {
            templatesByKey.TryGetValue(deal.TemplateKey, out var template);
            var title = template is null ? deal.TemplateKey : TranslationResolver.Resolve(template.Translations, language).Title;
            var domain = template?.Domain ?? string.Empty;

            return new DealSummaryDto(
                deal.Id,
                deal.TemplateKey,
                title,
                domain,
                ResolveHistoryStatus(deal, profileId),
                deal.SecondPartyName,
                deal.CreatedAt,
                deal.UpdatedAt);
        }).ToList();

        return new DealHistoryPageDto(items, totalCount, page, pageSize);
    }

    /// <summary>
    /// Collapses <see cref="DealStatus"/> + <see cref="InviteStatus"/> +
    /// signature timestamps into the five buckets the history UI shows.
    /// Neither status alone carries this: <c>DealStatus</c> only ever
    /// becomes non-Draft at generation/cancellation/full-signature, and
    /// <c>InviteStatus</c> only tracks the second party's own invite flow -
    /// so "waiting for the other side to sign" has to be derived from
    /// which of the two signature timestamps is still null for whichever
    /// side isn't the viewer.
    /// </summary>
    private static string ResolveHistoryStatus(Deal deal, string profileId)
    {
        if (deal.Status == DealStatus.Cancelled || deal.InviteStatus == InviteStatus.Declined)
            return "Cancelled";

        if (deal.Status == DealStatus.FullySigned)
            return "Signed";

        if (deal.SecondPartyProfileId is null)
            return deal.GeneratedHtml is null ? "Draft" : "WaitingSecondParty";

        var viewerIsSecondParty = deal.SecondPartyProfileId == profileId;
        var viewerSignedAt = viewerIsSecondParty ? deal.SecondPartySignedAt : deal.FirstPartySignedAt;

        return viewerSignedAt is null ? "WaitingYourSignature" : "WaitingSecondParty";
    }
}
