using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class MergedFieldServiceTests
{
    [Fact]
    public async Task Vehicle_registration_fields_are_completed_before_interview_questions()
    {
        var fields = RequiredFields(
            (21, "vehicle make"),
            (22, "vehicle model"),
            (23, "VIN"),
            (24, "plate number"),
            (32, "sale price"));
        var documents = Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["vehicle_make"] = new("Toyota", 0.97),
            ["vehicle_model"] = new("Camry", 0.97),
            ["vin"] = new("JTDBE32K123456789", 0.97),
            ["plate_number"] = new("01 A 777 AA", 0.97),
        });
        var mapper = new StaticChatClient(
            """{"fields":[{"fieldId":21,"value":"Toyota","confidence":0.97,"source":"document"},{"fieldId":22,"value":"Camry","confidence":0.97,"source":"document"},{"fieldId":23,"value":"JTDBE32K123456789","confidence":0.97,"source":"document"},{"fieldId":24,"value":"01 A 777 AA","confidence":0.97,"source":"document"}]}""");

        var result = await PlanAfterMerge(fields, documents, mapper);

        Assert.Equal(32, result.FieldId);
        Assert.False(result.Question!.Contains("VIN", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task Property_cadastre_fields_are_completed_before_interview_questions()
    {
        var fields = RequiredFields(
            (21, "property address"),
            (22, "cadastre number"),
            (23, "area"),
            (24, "rooms"),
            (32, "transfer date"));
        var documents = Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["property_address"] = new("Tashkent, Chilanzar 12", 0.94),
            ["cadastre_number"] = new("10:02:03:04:05", 0.94),
            ["area"] = new("72 sq m", 0.94),
            ["rooms"] = new("3", 0.94),
        });
        var mapper = new StaticChatClient(
            """{"fields":[{"fieldId":21,"value":"Tashkent, Chilanzar 12","confidence":0.94,"source":"document"},{"fieldId":22,"value":"10:02:03:04:05","confidence":0.94,"source":"document"},{"fieldId":23,"value":"72 sq m","confidence":0.94,"source":"document"},{"fieldId":24,"value":"3","confidence":0.94,"source":"document"}]}""");

        var result = await PlanAfterMerge(fields, documents, mapper);

        Assert.Equal(32, result.FieldId);
        Assert.False(result.Question!.Contains("cadastre", StringComparison.OrdinalIgnoreCase));
        Assert.False(result.Question.Contains("address", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task Employment_document_fields_are_completed_before_interview_questions()
    {
        var fields = RequiredFields(
            (11, "workplace"),
            (12, "position"),
            (13, "work time type"),
            (21, "salary"),
            (32, "contract end date"));
        var documents = Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["workplace"] = new("Tashkent office", 0.93),
            ["position"] = new("Accountant", 0.93),
            ["work_time_type"] = new("Full time", 0.93),
            ["salary"] = new("8,000,000 UZS", 0.93),
        });
        var mapper = new StaticChatClient(
            """{"fields":[{"fieldId":11,"value":"Tashkent office","confidence":0.93,"source":"document"},{"fieldId":12,"value":"Accountant","confidence":0.93,"source":"document"},{"fieldId":13,"value":"Full time","confidence":0.93,"source":"document"},{"fieldId":21,"value":"8,000,000 UZS","confidence":0.93,"source":"document"}]}""");

        var result = await PlanAfterMerge(fields, documents, mapper);

        Assert.Equal(32, result.FieldId);
        Assert.False(result.Question!.Contains("salary", StringComparison.OrdinalIgnoreCase));
        Assert.False(result.Question.Contains("position", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task Low_confidence_document_fields_are_not_completed()
    {
        var fields = RequiredFields((21, "vehicle make"), (32, "sale price"));
        var documents = Documents(new Dictionary<string, ExtractedFieldValue>
        {
            ["vehicle_make"] = new("Toyota", 0.60),
        });
        var mapper = new StaticChatClient(
            """{"fields":[{"fieldId":21,"value":"Toyota","confidence":0.60,"source":"document"}]}""");

        var result = await PlanAfterMerge(fields, documents, mapper);

        Assert.Equal(21, result.FieldId);
    }

    [Fact]
    public void Preprocessed_fields_do_not_overwrite_user_answers()
    {
        var answers = new Dictionary<int, string> { [21] = "User value" };
        var collection = new MergedFieldCollection(new Dictionary<int, MergedFieldValue>
        {
            [21] = new(21, "Document value", 0.99, "document"),
        });

        collection.ApplyHighConfidenceAnswers(answers);

        Assert.Equal("User value", answers[21]);
    }

    [Fact]
    public void Refresh_removes_only_unchanged_owned_answers()
    {
        var answers = new Dictionary<int, string>
        {
            [21] = "Old document value",
            [22] = "User override",
            [23] = "Conversation answer",
        };
        var previous = new MergedFieldCollection(new Dictionary<int, MergedFieldValue>
        {
            [21] = new(21, "Old document value", 0.99, "document"),
            [22] = new(22, "Old document value", 0.99, "document"),
            [23] = new(23, "Conversation answer", 1.0, "conversation"),
        });

        previous.RemoveOwnedAnswers(answers);

        Assert.False(answers.ContainsKey(21));
        Assert.Equal("User override", answers[22]);
        Assert.Equal("Conversation answer", answers[23]);
    }

    private static async Task<InterviewPlanResult> PlanAfterMerge(
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyList<UploadedDocument> documents,
        StaticChatClient mapper,
        IReadOnlyDictionary<int, string>? labels = null)
    {
        labels ??= fields.ToDictionary(f => f.FieldId, f => f.FieldId.ToString());
        var answers = DealAnswersSerializer.Deserialize(null);
        var mergedFields = await new MergedFieldService(mapper)
            .BuildAsync(fields, labels, answers, documents, null);

        mergedFields.ApplyHighConfidenceAnswers(answers);

        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient("""{"question":"What missing field is still needed?","extracted":{}}""")));
        return await planner.ExecuteAsync(
            "Test agreement",
            "en",
            null,
            null,
            mergedFields,
            fields,
            labels,
            answers,
            CancellationToken.None);
    }

    private static IReadOnlyList<AgreementTemplateField> RequiredFields(params (int Id, string Label)[] fields)
    {
        return fields.Select(field =>
        {
            return new AgreementTemplateField
            {
                Id = Guid.NewGuid(),
                AgreementTemplateId = Guid.NewGuid(),
                FieldId = field.Id,
                Mode = AgreementFieldMode.Required,
            };
        }).ToList();
    }

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
    private sealed class StaticChatClient(string response) : IAiChatClient
    {
        public Task<string> CompleteAsync(
            string systemPrompt,
            string userMessage,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(response);
    }
}
