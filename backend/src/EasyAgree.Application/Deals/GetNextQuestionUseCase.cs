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

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var (title, _) = TranslationResolver.Resolve(template.Translations, language);

        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var documentHints = DocumentFieldHintCollection.FromDocuments(documents);

        var result = await conversationManager.ExecuteAsync(
            template.Domain, title, language, deal.RequestText, documentHints, answeredFieldId, answerText, currentQuestionText,
            template.Fields, labels, answers, askedQuestions, dismissedDocumentSuggestions, cancellationToken);

        await SaveAsync(deal, answers, askedQuestions, cancellationToken);

        if (result.IsSuggestDocument)
            return NextQuestionResult.SuggestDocument(result.SuggestedDocumentType!.Value, result.SuggestedMatchedFieldCount);

        return result.IsReady
            ? NextQuestionResult.ReadyToGenerate(result.Question!)
            : NextQuestionResult.NeedMoreInfo(result.FieldId!.Value, result.Question!);
    }

    private async Task SaveAsync(
        Deal deal, Dictionary<int, string> answers, Dictionary<string, string> askedQuestions, CancellationToken cancellationToken)
    {
        deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
        deal.AskedQuestionsJson = DealAskedQuestionsSerializer.Serialize(askedQuestions);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }
}
