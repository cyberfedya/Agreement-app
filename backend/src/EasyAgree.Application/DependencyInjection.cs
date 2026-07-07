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

        return services;
    }
}
