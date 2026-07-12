using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class DocumentConflictEngineTests
{
    [Fact]
    public void Detects_conflicting_vins_without_mutating_raw_document_values()
    {
        var first = Document("first.jpg", new Dictionary<string, ExtractedFieldValue> { ["vin"] = new("JHMCM56557C404453", 0.99) });
        var second = Document("second.jpg", new Dictionary<string, ExtractedFieldValue> { ["vin"] = new("XW8ZZZ61ZHG000001", 0.98) });

        var conflict = Assert.Single(DocumentConflictEngine.Detect([first, second]));

        Assert.Equal("VIN_MISMATCH", conflict.Type);
        Assert.Equal("HIGH", conflict.Severity);
        Assert.Equal(2, conflict.Values.Count);
        Assert.Equal("JHMCM56557C404453", ExtractedDocumentFieldsSerializer.Deserialize(first.ExtractedFieldsJson)["vin"].Value);
    }

    [Fact]
    public void Ignores_equivalent_identifier_formatting()
    {
        var first = Document("first.jpg", new Dictionary<string, ExtractedFieldValue> { ["vin"] = new("JHM-CM56557C404453", 0.99) });
        var second = Document("second.jpg", new Dictionary<string, ExtractedFieldValue> { ["vin"] = new("jhmcm56557c404453", 0.98) });

        Assert.Empty(DocumentConflictEngine.Detect([first, second]));
    }

    private static UploadedDocument Document(string fileName, IReadOnlyDictionary<string, ExtractedFieldValue> fields) => new()
    {
        Id = Guid.NewGuid(), DealId = Guid.NewGuid(), FileName = fileName, ContentType = "image/jpeg", StoragePath = fileName,
        UploadedAt = DateTime.UtcNow, Status = DocumentProcessingStatus.Processed,
        ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(fields),
    };
}
