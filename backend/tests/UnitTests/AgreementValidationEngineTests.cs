using EasyAgree.Application.Documents;
using EasyAgree.Application.Validation;

namespace UnitTests;

public sealed class AgreementValidationEngineTests
{
    [Fact]
    public void Reports_missing_required_fields_and_document_conflicts()
    {
        var conflict = new DocumentConflict("VIN_MISMATCH", "vin", "HIGH", "Documents disagree", "Verify VIN", []);
        var result = AgreementValidationEngine.Validate([(1, "vehicle VIN"), (2, "sale price")],
            new Dictionary<int, string> { [1] = "JHMCM56557C404453" }, [conflict]);

        Assert.False(result.IsValid);
        Assert.Contains(result.Issues, issue => issue.Code == "MISSING_REQUIRED_FIELD" && issue.FieldId == 2);
        Assert.Contains(result.Issues, issue => issue.Code == "DOCUMENT_VIN_MISMATCH");
    }

    [Fact]
    public void Accepts_complete_plausible_values_without_conflicts()
    {
        var result = AgreementValidationEngine.Validate([(1, "vehicle VIN"), (2, "sale price")],
            new Dictionary<int, string> { [1] = "JHMCM56557C404453", [2] = "18000" }, []);

        Assert.True(result.IsValid);
        Assert.Empty(result.Issues);
    }
}
