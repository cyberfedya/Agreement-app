namespace EasyAgree.Contracts.Deals;

public sealed record DealDto(Guid Id, string TemplateKey, string TemplateTitle, string Status);
