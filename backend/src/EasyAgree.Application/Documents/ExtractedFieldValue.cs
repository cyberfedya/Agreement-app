namespace EasyAgree.Application.Documents;

/// <summary>One piece of information read from a document, with how sure the model was.</summary>
public sealed record ExtractedFieldValue(string Value, double Confidence);
