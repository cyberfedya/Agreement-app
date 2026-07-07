namespace EasyAgree.Domain.Entities;

public class AgreementTemplateTranslation
{
    public Guid Id { get; set; }

    public Guid AgreementTemplateId { get; set; }

    public required string Language { get; set; }

    public required string Title { get; set; }

    public required string Description { get; set; }

    public AgreementTemplate? AgreementTemplate { get; set; }
}
