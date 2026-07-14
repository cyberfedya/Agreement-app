using EasyAgree.Application.Deals.Interview;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>Discriminated outcome of asking the interview planner what to do next.</summary>
public sealed class NextQuestionResult
{
    public bool IsNotFound { get; private init; }

    public bool IsReadyToGenerate { get; private init; }

    public bool IsSuggestDocument { get; private init; }

    public int? NextFieldId { get; private init; }

    public string? NextQuestion { get; private init; }

    public InterviewStage? Stage { get; private init; }

    public DocumentType? SuggestedDocumentType { get; private init; }

    public int SuggestedMatchedFieldCount { get; private init; }

    public static NextQuestionResult NotFound() => new() { IsNotFound = true };

    public static NextQuestionResult ReadyToGenerate(string closingMessage) =>
        new() { IsReadyToGenerate = true, NextQuestion = closingMessage };

    public static NextQuestionResult NeedMoreInfo(int fieldId, string question, InterviewStage? stage) =>
        new() { NextFieldId = fieldId, NextQuestion = question, Stage = stage };

    public static NextQuestionResult SuggestDocument(DocumentType documentType, int matchedFieldCount) =>
        new() { IsSuggestDocument = true, SuggestedDocumentType = documentType, SuggestedMatchedFieldCount = matchedFieldCount };
}
