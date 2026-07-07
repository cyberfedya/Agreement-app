namespace EasyAgree.Domain.Entities;

public class AgreementTemplate
{
    public Guid Id { get; set; }

    public required string Domain { get; set; }

    public required string Key { get; set; }

    public string? SourceUrl { get; set; }

    public required string HtmlTemplate { get; set; }

    public bool IsActive { get; set; } = true;

    public int Version { get; set; } = 1;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public List<AgreementTemplateTranslation> Translations { get; set; } = [];

    public List<AgreementTemplateField> Fields { get; set; } = [];
}
