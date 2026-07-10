using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Application.Profile;
using EasyAgree.Application.Templates;
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
        services.AddScoped<GenerateFromDealUseCase>();
        services.AddScoped<GetDealAgreementUseCase>();
        services.AddScoped<GetDealInviteUseCase>();
        services.AddScoped<AcceptDealInviteUseCase>();
        services.AddScoped<SignDealSecondPartyUseCase>();

        services.AddScoped<GetUserProfileUseCase>();
        services.AddScoped<SaveUserProfileUseCase>();

        services.AddScoped<UploadDocumentsUseCase>();
        services.AddScoped<GetDealDocumentsUseCase>();
        services.AddScoped<GetRequiredDocumentsUseCase>();
        services.AddScoped<DeleteDocumentUseCase>();
        services.AddScoped<GetInterviewPreviewUseCase>();
        services.AddScoped<UpdateDocumentFieldUseCase>();
        services.AddScoped<IntakePreprocessingService>();
        services.AddScoped<DocumentConsistencyChecker>();

        return services;
    }
}
