namespace EasyAgree.Contracts.Templates;

public sealed record QuestionDto(int FieldId, string FieldName, bool Required, string Type);
