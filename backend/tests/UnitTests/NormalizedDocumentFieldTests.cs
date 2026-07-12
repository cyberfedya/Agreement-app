using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class NormalizedDocumentFieldTests
{
    [Fact]
    public void User_override_becomes_effective_without_mutating_raw_extraction()
    {
        var raw = new Dictionary<string, ExtractedFieldValue>
        {
            ["vin"] = new("BAD-OCR-VIN", 0.53),
        };
        var normalized = new Dictionary<string, NormalizedDocumentFieldValue>
        {
            ["vin"] = new("XW8ZZZ61ZHG000001", 1.0, "user_override", "CONFIRMED", "vin"),
        };
        var document = new UploadedDocument
        {
            Id = Guid.NewGuid(),
            DealId = Guid.NewGuid(),
            FileName = "vehicle.jpg",
            ContentType = "image/jpeg",
            StoragePath = "vehicle.jpg",
            UploadedAt = DateTime.UtcNow,
            Status = DocumentProcessingStatus.Processed,
            ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(raw),
            NormalizedFieldsJson = NormalizedDocumentFieldsSerializer.Serialize(normalized),
        };

        var hints = DocumentFieldHintCollection.FromDocuments([document]);

        Assert.Equal("BAD-OCR-VIN", ExtractedDocumentFieldsSerializer.Deserialize(document.ExtractedFieldsJson)["vin"].Value);
        var effective = Assert.Single(hints.Fields);
        Assert.Equal("XW8ZZZ61ZHG000001", effective.Value);
        Assert.Equal("user_override", effective.Source);
    }
}
