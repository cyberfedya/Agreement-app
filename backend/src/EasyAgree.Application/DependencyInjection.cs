using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Profile;
using EasyAgree.Application.Templates;
using EasyAgree.Application.Legal;
using EasyAgree.Application.Quality;
using EasyAgree.Application.Validation;
using EasyAgree.Application.Risk;
using Microsoft.Extensions.DependencyInjection;

namespace EasyAgree.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<GetTemplatesUseCase>();
        services.AddScoped<GetTemplateUseCase>();
        services.AddScoped<GetQuestionsUseCase>();
        services.AddScoped<GenerateAgreementUseCase>();

        services.AddScoped<CreateDealUseCase>();
        services.AddScoped<GetDealUseCase>();
        services.AddScoped<GetDealQuestionsUseCase>();
        services.AddScoped<QuestionGenerator>();
        services.AddScoped<InterviewPlanner>();
        services.AddScoped<IntentClassifier>();
        services.AddScoped<SideQuestionAnswerer>();
        services.AddScoped<ConversationManager>();
        services.AddScoped<GetNextQuestionUseCase>();
        services.AddScoped<PartyRoleClassifier>();
        services.AddScoped<PartyProfileResolver>();
        services.AddScoped<GenerateFromDealUseCase>();
        services.AddScoped<GetDealAgreementUseCase>();
        services.AddScoped<VerifyDealDocumentUseCase>();
        services.AddScoped<GetDealFieldStatesUseCase>();
        services.AddScoped<GetDealReviewUseCase>();
        services.AddScoped<GetDealQualityUseCase>();
        services.AddScoped<GetDealAgreementValidationUseCase>();
        services.AddScoped<GetDealRiskAssessmentUseCase>();
        services.AddScoped<GetDealInviteUseCase>();
        services.AddScoped<AcceptDealInviteUseCase>();
        services.AddScoped<DeclineDealInviteUseCase>();
        services.AddScoped<ProposeDealFieldChangeUseCase>();
        services.AddScoped<RequestDealClarificationUseCase>();
        services.AddScoped<SignDealSecondPartyUseCase>();
        services.AddScoped<SignDealFirstPartyUseCase>();
        services.AddScoped<DismissDocumentSuggestionUseCase>();

        services.AddScoped<GetUserProfileUseCase>();
        services.AddScoped<SaveUserProfileUseCase>();

        services.AddScoped<UploadDocumentsUseCase>();
        services.AddScoped<GetDealDocumentsUseCase>();
        services.AddScoped<GetDealDocumentConflictsUseCase>();
        services.AddScoped<GetRequiredDocumentsUseCase>();
        services.AddScoped<DeleteDocumentUseCase>();
        services.AddScoped<GetInterviewPreviewUseCase>();
        services.AddScoped<UpdateDocumentFieldUseCase>();
        services.AddScoped<IntakePreprocessingService>();
        services.AddScoped<DocumentConsistencyChecker>();
        services.AddSingleton<ILegalKnowledgeProvider, MoneyKnowledgeProvider>();
        services.AddSingleton<ILegalKnowledgeProvider, VehicleKnowledgeProvider>();
        services.AddSingleton<ILegalKnowledgeProvider, AddressKnowledgeProvider>();
        services.AddSingleton<ILegalKnowledgeProvider, PropertyKnowledgeProvider>();
        services.AddSingleton<ILegalKnowledgeProvider>(new DateKnowledgeProvider(TimeProvider.System));
        services.AddSingleton<LegalKnowledgeEngine>();

        return services;
    }
}
