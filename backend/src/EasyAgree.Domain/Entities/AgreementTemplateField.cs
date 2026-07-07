using EasyAgree.Domain.Enums;

namespace EasyAgree.Domain.Entities;

public class AgreementTemplateField
{
    public Guid Id { get; set; }

    public Guid AgreementTemplateId { get; set; }

    public int FieldId { get; set; }

    public AgreementFieldMode Mode { get; set; } = AgreementFieldMode.Required;

    public AgreementTemplate? AgreementTemplate { get; set; }
}
