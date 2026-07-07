namespace EasyAgree.Infrastructure.AI;

public sealed class AiOptions
{
    public const string SectionName = "Ai";

    /// <summary>Base URL of the OpenAI-compatible inference server (e.g. a vLLM deployment).</summary>
    public string BaseUrl { get; set; } = string.Empty;

    /// <summary>Bearer token for the inference server. Keep out of appsettings.json — set via
    /// user-secrets locally or the Ai__ApiKey environment variable in Docker/production.</summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>Model id as reported by the server's /v1/models endpoint.</summary>
    public string Model { get; set; } = string.Empty;
}
