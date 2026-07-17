using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Thin adapter between the deal/template persistence layer and the
/// <see cref="ConversationManager"/>: loads state, delegates the actual
/// intent classification + planning, then persists whatever ended up
/// written to the answer set before returning.
/// </summary>
public sealed class GetNextQuestionUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository,
    ConversationManager conversationManager)
{
    public async Task<NextQuestionResult> ExecuteAsync(
        Guid dealId,
        int? answeredFieldId,
        string? answerText,
        string? currentQuestionText,
        string language,
        CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return NextQuestionResult.NotFound();

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return NextQuestionResult.NotFound();

        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var askedQuestions = DealAskedQuestionsSerializer.Deserialize(deal.AskedQuestionsJson);
        var dismissedDocumentSuggestions = DealDismissedDocumentSuggestionsSerializer.Deserialize(deal.DismissedDocumentSuggestionsJson);
        var deferredFieldIds = DealDeferredFieldIdsSerializer.Deserialize(deal.DeferredFieldIdsJson);

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var (title, _) = TranslationResolver.Resolve(template.Translations, language);

        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var documentHints = DocumentFieldHintCollection.FromDocuments(documents);

        var result = await conversationManager.ExecuteAsync(
            template.Domain, title, language, deal.RequestText, documentHints, answeredFieldId, answerText, currentQuestionText,
            template.Fields, labels, answers, askedQuestions, dismissedDocumentSuggestions, deferredFieldIds, cancellationToken);

        await SaveAsync(deal, answers, askedQuestions, deferredFieldIds, cancellationToken);

        if (result.IsSuggestDocument)
            return NextQuestionResult.SuggestDocument(result.SuggestedDocumentType!.Value, result.SuggestedMatchedFieldCount);

        if (result.IsReady)
            return NextQuestionResult.ReadyToGenerate(result.Question!);

        var stage = ResolveStage(template.Domain, template.Fields, labels, result.FieldId!.Value, language);
        return NextQuestionResult.NeedMoreInfo(result.FieldId!.Value, result.Question!, stage, result.GroupFieldIds);
    }

    /// <summary>
    /// Purely a read-side annotation of whichever field the planner already
    /// chose to ask - reuses the same deterministic classification
    /// <see cref="GetDealFieldStatesUseCase"/> uses, so it never
    /// second-guesses <see cref="ConversationManager"/>'s actual decision.
    /// </summary>
    private static InterviewStage? ResolveStage(
        string domain,
        IReadOnlyList<AgreementTemplateField> fields,
        IReadOnlyDictionary<int, string> labels,
        int fieldId,
        string language)
    {
        var classified = FieldEligibilityEngine.Classify(fields, labels).FirstOrDefault(f => f.FieldId == fieldId);
        return classified is null ? null : InterviewStageCatalog.Resolve(domain, classified.Category, language);
    }

    private async Task SaveAsync(
        Deal deal,
        Dictionary<int, string> answers,
        Dictionary<string, string> askedQuestions,
        ISet<int> deferredFieldIds,
        CancellationToken cancellationToken)
    {
        deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
        deal.AskedQuestionsJson = DealAskedQuestionsSerializer.Serialize(askedQuestions);
        deal.DeferredFieldIdsJson = DealDeferredFieldIdsSerializer.Serialize((IReadOnlySet<int>)deferredFieldIds);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }
}