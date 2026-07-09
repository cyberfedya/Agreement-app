using System.ClientModel;
using EasyAgree.Infrastructure.AI;
using Microsoft.Extensions.Configuration;
using OpenAI;
using OpenAI.Chat;

namespace IntegrationTests;

/// <summary>
/// Proves the connection to the configured inference server actually works.
/// Reads Ai:BaseUrl/Model from EasyAgree.Api/appsettings.json and Ai:ApiKey
/// from the same UserSecretsId Api uses (or an Ai__ApiKey env var) — the key
/// never appears in source. Requires real network access to the server.
/// </summary>
public class AiConnectionTests
{
    private const string ApiUserSecretsId = "032567a5-af61-4bbf-921e-72da595d708b";

    [Fact]
    public async Task ChatClient_completes_a_real_round_trip_against_the_connected_server()
    {
        var config = BuildConfiguration();
        var aiSection = config.GetSection("Ai");
        var apiKey = aiSection["ApiKey"];

        // Live-LLM test is opt-in: without a key (e.g. in CI, which has no
        // access to the inference server) there is nothing meaningful to
        // verify, so pass vacuously instead of failing the build. To run it
        // for real: dotnet user-secrets set "Ai:ApiKey" "<key>" in
        // backend/src/EasyAgree.Api, or set the Ai__ApiKey env var.
        if (string.IsNullOrWhiteSpace(apiKey))
            return;

        var chatClient = new ChatClient(
            aiSection["Model"],
            new ApiKeyCredential(apiKey!),
            new OpenAIClientOptions { Endpoint = new Uri(aiSection["BaseUrl"]!.TrimEnd('/') + "/v1") });

        var sut = new VllmChatClient(chatClient);

        var reply = await sut.CompleteAsync(
            "You are a terse assistant.",
            "Reply with exactly one word: PONG");

        Assert.Contains("PONG", reply, StringComparison.OrdinalIgnoreCase);
    }

    private static IConfiguration BuildConfiguration() =>
        new ConfigurationBuilder()
            .AddJsonFile(FindApiAppSettings(), optional: false)
            .AddUserSecrets(ApiUserSecretsId)
            .AddEnvironmentVariables()
            .Build();

    private static string FindApiAppSettings()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        for (var i = 0; i < 10 && dir is not null; i++)
        {
            var candidate = Path.Combine(dir.FullName, "src", "EasyAgree.Api", "appsettings.json");
            if (File.Exists(candidate))
                return candidate;
            dir = dir.Parent;
        }

        throw new FileNotFoundException("Could not locate EasyAgree.Api/appsettings.json by walking up from the test binary.");
    }
}
