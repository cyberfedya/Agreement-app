namespace EasyAgree.Application.Deals;

/// <summary>Discriminated outcome of asking the interview planner what to do next.</summary>
public sealed class NextQuestionResult
{
    public bool IsNotFound { get; private init; }

    public bool IsReadyToGenerate { get; private init; }

    public int? NextFieldId { get; private init; }

    public string? NextQuestion { get; private init; }

    public static NextQuestionResult NotFound() => new() { IsNotFound = true };

    public static NextQuestionResult ReadyToGenerate(string closingMessage) =>
        new() { IsReadyToGenerate = true, NextQuestion = closingMessage };

    public static NextQuestionResult NeedMoreInfo(int fieldId, string question) =>
        new() { NextFieldId = fieldId, NextQuestion = question };
}
