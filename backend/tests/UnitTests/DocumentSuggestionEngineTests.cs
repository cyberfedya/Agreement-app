using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace UnitTests;

public sealed class DocumentSuggestionEngineTests
{
    private static readonly IReadOnlyList<ClassifiedField> VehicleAskable =
    [
        new(21, "кузов рақами", FieldCategory.RequiredObject),
        new(22, "шасси рақами", FieldCategory.RequiredObject),
        new(23, "двигатель рақами", FieldCategory.RequiredObject),
        new(24, "давлат рақам белгиси", FieldCategory.RequiredObject),
    ];

    [Fact]
    public void Suggests_when_at_least_three_extractable_fields_are_missing()
    {
        var decision = DocumentSuggestionEngine.Evaluate(
            "vehicle", VehicleAskable, DocumentFieldHintCollection.Empty, new HashSet<string>());

        Assert.NotNull(decision);
        Assert.Equal(DocumentType.VehicleRegistration, decision!.DocumentType);
        Assert.Equal(4, decision.MatchedFieldCount);
    }

    [Fact]
    public void Does_not_suggest_when_below_the_minimum_matched_fields()
    {
        var askable = VehicleAskable.Take(2).ToList();

        var decision = DocumentSuggestionEngine.Evaluate(
            "vehicle", askable, DocumentFieldHintCollection.Empty, new HashSet<string>());

        Assert.Null(decision);
    }

    [Fact]
    public void Does_not_suggest_for_a_domain_with_no_catalog_entry()
    {
        var decision = DocumentSuggestionEngine.Evaluate(
            "loan", VehicleAskable, DocumentFieldHintCollection.Empty, new HashSet<string>());

        Assert.Null(decision);
    }

    [Fact]
    public void Does_not_suggest_once_dismissed()
    {
        var dismissed = new HashSet<string> { DocumentType.VehicleRegistration.ToString() };

        var decision = DocumentSuggestionEngine.Evaluate(
            "vehicle", VehicleAskable, DocumentFieldHintCollection.Empty, dismissed);

        Assert.Null(decision);
    }

    [Fact]
    public void Does_not_suggest_once_the_document_was_already_provided()
    {
        var hints = DocumentFieldHintCollection.FromDocuments(
        [
            new UploadedDocument
            {
                Id = Guid.NewGuid(),
                DealId = Guid.NewGuid(),
                FileName = "reg.jpg",
                ContentType = "image/jpeg",
                StoragePath = "reg.jpg",
                UploadedAt = DateTime.UtcNow,
                Status = DocumentProcessingStatus.Processed,
                ExtractedFieldsJson = ExtractedDocumentFieldsSerializer.Serialize(
                    new Dictionary<string, ExtractedFieldValue> { ["vin"] = new("SHU12345", 0.9) }),
            },
        ]);

        var decision = DocumentSuggestionEngine.Evaluate("vehicle", VehicleAskable, hints, new HashSet<string>());

        Assert.Null(decision);
    }

    [Fact]
    public async Task Planner_returns_suggestion_instead_of_a_question_when_criteria_are_met()
    {
        var fields = VehicleAskable.Select(f => new AgreementTemplateField
        {
            Id = Guid.NewGuid(),
            AgreementTemplateId = Guid.NewGuid(),
            FieldId = f.FieldId,
            Mode = AgreementFieldMode.Required,
        }).ToList();
        var labels = VehicleAskable.ToDictionary(f => f.FieldId, f => f.Label);
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient("n/a")));

        var result = await planner.ExecuteAsync(
            "vehicle", "Vehicle sale", "ru", null, null, DocumentFieldHintCollection.Empty,
            fields, labels, DealAnswersSerializer.Deserialize(null), new Dictionary<string, string>(),
            new HashSet<string>(), new HashSet<int>(), CancellationToken.None);

        Assert.True(result.IsSuggestDocument);
        Assert.Equal(DocumentType.VehicleRegistration, result.SuggestedDocumentType);
        Assert.Null(result.FieldId);
    }

    [Fact]
    public async Task Planner_asks_a_normal_question_after_the_suggestion_is_dismissed()
    {
        var fields = VehicleAskable.Select(f => new AgreementTemplateField
        {
            Id = Guid.NewGuid(),
            AgreementTemplateId = Guid.NewGuid(),
            FieldId = f.FieldId,
            Mode = AgreementFieldMode.Required,
        }).ToList();
        var labels = VehicleAskable.ToDictionary(f => f.FieldId, f => f.Label);
        var planner = new InterviewPlanner(new QuestionGenerator(new StaticChatClient(
            """{"question":"Подскажите VIN, номер кузова, шасси и двигателя?","extracted":{}}""")));
        var dismissed = new HashSet<string> { DocumentType.VehicleRegistration.ToString() };

        var result = await planner.ExecuteAsync(
            "vehicle", "Vehicle sale", "ru", null, null, DocumentFieldHintCollection.Empty,
            fields, labels, DealAnswersSerializer.Deserialize(null), new Dictionary<string, string>(),
            dismissed, new HashSet<int>(), CancellationToken.None);

        Assert.False(result.IsSuggestDocument);
        Assert.NotNull(result.FieldId);
    }

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
