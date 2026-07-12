using EasyAgree.Application.Documents;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Validation;

namespace EasyAgree.Application.Risk;

/// <summary>Rule-based, reproducible risk calculation. It only evaluates
/// known state; no LLM, mutation, or hidden external dependency is used.</summary>
public static class AgreementRiskEngine
{
    public static AgreementRiskAssessment Assess(
        AgreementValidationResult validation,
        AgreementQualityScore quality,
        IReadOnlyList<DocumentConflict> conflicts,
        bool hasGeneratedAgreement,
        bool secondPartySigned)
    {
        var issues = new List<AgreementRiskIssue>();
        var missing = validation.Issues.Count(issue => issue.Code == "MISSING_REQUIRED_FIELD");
        var invalid = validation.Issues.Count(issue => issue.Code == "INVALID_FIELD_VALUE");

        if (missing > 0)
            issues.Add(new("MISSING_REQUIRED_DATA", "HIGH", null, "Required data is missing",
                $"{missing} required field(s) have no trusted value.", "Provide or upload the missing information.", false));
        if (invalid > 0)
            issues.Add(new("INVALID_FIELD_FORMAT", "HIGH", null, "Field format requires review",
                $"{invalid} field value(s) fail deterministic format checks.", "Correct the invalid values before signing.", false));
        foreach (var conflict in conflicts)
            issues.Add(new("CONFLICT_" + conflict.Type, conflict.Severity, conflict.Field, "Conflicting document facts",
                conflict.Reason, conflict.RecommendedResolution, false));
        if (!hasGeneratedAgreement)
            issues.Add(new("AGREEMENT_NOT_GENERATED", "HIGH", null, "Agreement draft is unavailable",
                "Risk cannot be assessed against final agreement text before a draft is generated.", "Generate and review the agreement before signing.", false));
        if (!secondPartySigned)
            issues.Add(new("SECOND_PARTY_NOT_SIGNED", "MEDIUM", null, "Second-party signature is pending",
                "The agreement is not yet accepted by the second party.", "Complete the QR/signature flow before finalizing.", false));
        if (quality.DocumentConfidence < 0.75)
            issues.Add(new("LOW_DOCUMENT_CONFIDENCE", "MEDIUM", null, "Document extraction confidence is low",
                "One or more document values were extracted with limited confidence.", "Review document-derived values before signing.", false));

        var categories = new List<RiskCategory>
        {
            new("Data Completeness", Math.Min(100, missing * 25), missing == 0 ? "Required data is present." : "Required values are missing."),
            new("Legal Completeness", 100 - (int)Math.Round(quality.RequiredCompletion * 100), "Based on required agreement fields."),
            new("Document Consistency", 100 - (int)Math.Round(quality.Consistency * 100), conflicts.Count == 0 ? "Documents are consistent." : "Documents contain contradictions."),
            new("Field Conflicts", Math.Min(100, conflicts.Count * 35), conflicts.Count == 0 ? "No tracked field conflicts." : "Conflicts require explicit resolution."),
            new("Payment Risk", validation.Issues.Any(issue => (issue.Label ?? "").Contains("price", StringComparison.OrdinalIgnoreCase)) ? 35 : 0, "Based on payment-related required values."),
            new("Transfer Risk", validation.Issues.Any(issue => (issue.Label ?? "").Contains("date", StringComparison.OrdinalIgnoreCase)) ? 25 : 0, "Based on transfer-related required values."),
            new("Signature Risk", secondPartySigned ? 0 : 30, secondPartySigned ? "Second party has signed." : "Second-party signature is pending."),
            new("Missing Clauses", 0, "Clause recommendations are advisory and do not alter the draft."),
            new("Document Confidence", 100 - (int)Math.Round(quality.DocumentConfidence * 100), "Based on extracted document confidence."),
        };

        var overall = (int)Math.Round(categories.Average(category => category.Risk), MidpointRounding.AwayFromZero);
        var confidence = Math.Clamp((int)Math.Round(100 * Math.Min(quality.DocumentConfidence, quality.Consistency), MidpointRounding.AwayFromZero), 0, 100);
        var level = overall switch { < 25 => "LOW", < 50 => "MEDIUM", < 75 => "HIGH", _ => "CRITICAL" };
        var summary = issues.Count == 0
            ? "Agreement is generally safe based on the currently available deterministic checks."
            : $"Agreement has {issues.Count} issue(s) requiring review before signing.";
        return new AgreementRiskAssessment(overall, level, confidence, summary, categories, issues, AgreementRecommendationEngine.Create(issues));
    }
}
