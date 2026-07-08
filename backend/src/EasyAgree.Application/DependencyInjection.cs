using EasyAgree.Application.Deals;
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
        services.AddScoped<GenerateFromDealUseCase>();

        return services;
    }
}
