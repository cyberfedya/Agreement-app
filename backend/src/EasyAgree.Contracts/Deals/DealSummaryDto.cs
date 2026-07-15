namespace EasyAgree.Contracts.Deals;

/// <summary>One card's worth of data for the Deal History list — deliberately smaller than <see cref="DealDto"/>, which carries interview-flow fields the list view never needs.</summary>
public sealed record DealSummaryDto(
    Guid Id,
    string TemplateKey,
    string TemplateTitle,
    string TemplateDomain,
    string HistoryStatus,
    string? SecondPartyName,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public sealed record DealHistoryPageDto(IReadOnlyList<DealSummaryDto> Items, int TotalCount, int Page, int PageSize);
