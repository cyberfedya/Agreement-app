using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Validation;

/// <summary>Pure pre-generation validation. It reports deterministic issues
/// and never fills values, calls an LLM, or changes a deal.</summary>
public static class AgreementValidationEngine
{
    public static AgreementValidationResult Validate(
        IReadOnlyList<(int FieldId, string Label)> requiredFields,
        IReadOnlyDictionary<int, string> knownAnswers,
        IReadOnlyList<DocumentConflict> conflicts)
    {
        var issues = new List<AgreementValidationIssue>();
        foreach (var (fieldId, label) in requiredFields)
        {
            if (!knownAnswers.TryGetValue(fieldId, out var value) || string.IsNullOrWhiteSpace(value))
            {
                issues.Add(new("MISSING_REQUIRED_FIELD", "ERROR", fieldId, label,
                    $"Required field '{label}' has no trusted value.", "Provide or upload a reliable value."));
                continue;
            }

            if (!AnswerShapeValidator.LooksPlausible(label, value))
                issues.Add(new("INVALID_FIELD_VALUE", "ERROR", fieldId, label,
                    $"Value for '{label}' does not match the expected format.", "Correct the value before generation."));
        }

        foreach (var conflict in conflicts)
            issues.Add(new("DOCUMENT_" + conflict.Type, "ERROR", null, conflict.Field,
                conflict.Reason, conflict.RecommendedResolution));

        return new AgreementValidationResult(!issues.Any(issue => issue.Severity == "ERROR"), issues);
    }
}
