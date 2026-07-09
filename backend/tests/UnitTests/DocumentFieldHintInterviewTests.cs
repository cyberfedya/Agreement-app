using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class DocumentFieldHintInterviewTests
{
    [Fact]
    public async Task Focused_document_extraction_can_skip_current_vehicle_field()
    {
        var fields = RequiredFields((21, "vehicle make"), (22, "vehicle year"), (32, "sale price"));
        var documents = Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["vehicle_make"] = new("CHEVROLET", 0.97),
            ["vehicle_year"] = new("2019", 0.97),
        });
        var hints = DocumentFieldHintCollection.FromDocuments(documents);
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":null,"extracted":{"21":"CHEVROLET","22":"2019"}}""",
            """{"question":"What is the sale price?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await planner.ExecuteAsync(
            "Vehicle sale",
            "en",
            null,
            null,
            hints,
            fields,
            Labels(fields),
            answers,
            CancellationToken.None);

        Assert.Equal(32, result.FieldId);
        Assert.Equal("CHEVROLET", answers[21]);
        Assert.Equal("2019", answers[22]);
        Assert.False(answers.ContainsKey(32));
    }

    [Fact]
    public async Task Focused_document_extraction_can_skip_current_property_fields()
    {
        var fields = RequiredFields((21, "property address"), (22, "cadastre number"), (32, "transfer date"));
        var hints = DocumentFieldHintCollection.FromDocuments(Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["property_address"] = new("Tashkent, Chilanzar 12", 0.94),
            ["cadastre_number"] = new("10:02:03:04:05", 0.94),
        }));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":null,"extracted":{"21":"Tashkent, Chilanzar 12","22":"10:02:03:04:05"}}""",
            """{"question":"What transfer date should we use?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await planner.ExecuteAsync(
            "Apartment agreement",
            "en",
            null,
            null,
            hints,
            fields,
            Labels(fields),
            answers,
            CancellationToken.None);

        Assert.Equal(32, result.FieldId);
        Assert.Equal("Tashkent, Chilanzar 12", answers[21]);
        Assert.Equal("10:02:03:04:05", answers[22]);
    }

    [Fact]
    public async Task Focused_document_extraction_can_skip_current_employment_fields()
    {
        var fields = RequiredFields((11, "workplace"), (12, "position"), (32, "contract end date"));
        var hints = DocumentFieldHintCollection.FromDocuments(Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["workplace"] = new("Tashkent office", 0.93),
            ["position"] = new("Accountant", 0.93),
        }));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":null,"extracted":{"11":"Tashkent office","12":"Accountant"}}""",
            """{"question":"When does the contract end?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await planner.ExecuteAsync(
            "Employment contract",
            "en",
            null,
            null,
            hints,
            fields,
            Labels(fields),
            answers,
            CancellationToken.None);

        Assert.Equal(32, result.FieldId);
        Assert.Equal("Tashkent office", answers[11]);
        Assert.Equal("Accountant", answers[12]);
    }

    [Fact]
    public async Task Wrong_document_mapping_is_not_written_when_focused_generator_refuses_it()
    {
        var fields = RequiredFields((21, "vehicle make"), (22, "vehicle year"));
        var hints = DocumentFieldHintCollection.FromDocuments(Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["issued_date"] = new("15.03.2019", 1.0),
            ["chassis_number"] = new("SHU-556677", 1.0),
        }));
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":"What is the vehicle make and year?","extracted":{}}""")));
        var answers = DealAnswersSerializer.Deserialize(null);

        var result = await planner.ExecuteAsync(
            "Vehicle sale",
            "en",
            null,
            null,
            hints,
            fields,
            Labels(fields),
            answers,
            CancellationToken.None);

        Assert.Equal(21, result.FieldId);
        Assert.False(answers.ContainsKey(21));
        Assert.False(answers.ContainsKey(22));
    }

    [Fact]
    public void Raw_document_hints_keep_semantic_keys_without_template_mapping()
    {
        var hints = DocumentFieldHintCollection.FromDocuments(Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["vehicle_make"] = new("CHEVROLET", 0.97),
            ["issued_date"] = new("15.03.2019", 0.97),
        }));

        var prompt = hints.ToPromptContext();

        Assert.Contains("vehicle_make = CHEVROLET", prompt);
        Assert.Contains("issued_date = 15.03.2019", prompt);
    }

    private static IReadOnlyList<AgreementTemplateField> RequiredFields(params (int Id, string Label)[] fields) =>
        fields.Select(field => new AgreementTemplateField
        {
            Id = Guid.NewGuid(),
            AgreementTemplateId = Guid.NewGuid(),
            FieldId = field.Id,
            Mode = AgreementFieldMode.Required,
        }).ToList();

    private static IReadOnlyDictionary<int, string> Labels(IEnumerable<AgreementTemplateField> fields) =>
        fields.ToDictionary(f => f.FieldId, f => f.FieldId switch
        {
            11 => "workplace",
            12 => "position",
            21 => "vehicle make",
            22 => "vehicle year",
            32 => "sale price",
            _ => f.FieldId.ToString(),
        });

    private static IReadOnlyList<UploadedDocument> Documents(IReadOnlyDictionary<string, ExtractedFieldValue> fields) =>
    [
        new UploadedDocument
        {
            Id = Guid.NewGuid(),
            DealId = Guid.NewGuid(),
            FileName = "document.jpg",
            ContentType = "image/jpeg",
            StoragePath = "document.jpg",
            UploadedAt = DateTime.UtcNow,
            Status = DocumentProcessingStatus.Processed,
            ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(fields),
        },
    ];

    private sealed class StaticChatClient(params string[] responses) : IAiChatClient
    {
        private int _index;

        public Task<string> CompleteAsync(
            string systemPrompt,
            string userMessage,
            CancellationToken cancellationToken = default)
        {
            var response = responses[Math.Min(_index, responses.Length - 1)];
            _index++;
            return Task.FromResult(response);
        }
    }
}
