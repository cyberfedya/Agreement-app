using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Documents;
using EasyAgree.Infrastructure.AI;
using EasyAgree.Infrastructure.Documents;
using EasyAgree.Infrastructure.Persistence;
using EasyAgree.Infrastructure.Persistence.Repositories;
using EasyAgree.Infrastructure.Persistence.Seed;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using OpenAI;
using OpenAI.Chat;
using System.ClientModel;
namespace EasyAgree.Infrastructure; 
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string 'Default' is not configured.");

        services.AddDbContext<EasyAgreeDbContext>(dbOptions =>
            dbOptions.UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsAssembly(typeof(EasyAgreeDbContext).Assembly.FullName)));

        services.Configure<AgreementSeederOptions>(configuration.GetSection(AgreementSeederOptions.SectionName));
        services.AddScoped<AgreementJsonLoader>();
        services.AddScoped<AgreementSeeder>();
        services.AddScoped<AgreementSeedService>();

        services.AddScoped<IAgreementTemplateRepository, AgreementTemplateRepository>();
        services.AddScoped<IDealRepository, DealRepository>();
        services.AddScoped<IUserProfileRepository, UserProfileRepository>();
        services.AddScoped<IUploadedDocumentRepository, UploadedDocumentRepository>();

        services.Configure<FileStorageOptions>(configuration.GetSection(FileStorageOptions.SectionName));
        services.AddSingleton<IFileStorage, LocalFileStorage>();
        services.AddScoped<IDocumentAnalysisService, VisionDocumentAnalysisService>();
        services.AddScoped<IDocumentRequirementResolver, DocumentRequirementResolver>();
        services.AddScoped<IFieldMergeService, FieldMergeService>();

        services.Configure<AiOptions>(configuration.GetSection(AiOptions.SectionName));
        services.AddSingleton(sp =>
        {
            var options = sp.GetRequiredService<IOptions<AiOptions>>().Value;
            var credential = new ApiKeyCredential(
                string.IsNullOrWhiteSpace(options.ApiKey) ? "unset" : options.ApiKey);
            var clientOptions = new OpenAIClientOptions { Endpoint = new Uri(options.BaseUrl.TrimEnd('/') + "/v1") };
            return new ChatClient(options.Model, credential, clientOptions);
        });
        services.AddSingleton<IAiChatClient, VllmChatClient>();
        services.AddSingleton<IVisionAiClient, VllmVisionClient>();

        return services;
    }
} 