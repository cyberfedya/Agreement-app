using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals;

public sealed record DealInviteResult(
    Guid DealId,
    string TransactionType,
    string? FirstPartyRole,
    string? ExpectedSecondPartyRole,
    string? InvitedBy,
    string InviteStatus,
    DateTime? ExpiresAt);

/// <summary>
/// Invite metadata only - no agreement HTML, no full field set. This is
/// what the second device reads right after scanning the QR code, before
/// deciding whether to accept, so it can show "you've been invited as
/// the buyer" without first loading (or the invite recipient having to
/// scroll through) the whole document.
/// </summary>
public sealed class GetDealInviteUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUserProfileRepository profileRepository)
{
    private const string DefaultLanguage = "ru";

    public async Task<DealInviteResult?> ExecuteAsync(
        Guid dealId, string? language = null, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var (title, _) = TranslationResolver.Resolve(template.Translations, language ?? DefaultLanguage);
        var profile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);

        return new DealInviteResult(
            deal.Id,
            title,
            deal.FirstPartyRole,
            deal.ExpectedSecondPartyRole,
            profile?.FullName,
            deal.InviteStatus.ToString(),
            deal.InviteExpiresAt);
    }
}
