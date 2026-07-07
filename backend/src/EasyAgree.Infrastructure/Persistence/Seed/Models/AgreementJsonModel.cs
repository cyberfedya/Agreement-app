using System.Text.Json.Serialization;

namespace EasyAgree.Infrastructure.Persistence.Seed.Models;

/// <summary>
/// Mirrors the on-disk agreement JSON schema exactly. This is a pure DTO for
/// deserialization — it must never be written back to the source files.
/// </summary>
public sealed class AgreementJsonModel
{
    [JsonPropertyName("domain")]
    public string? Domain { get; set; }

    [JsonPropertyName("key")]
    public string? Key { get; set; }

    [JsonPropertyName("title")]
    public Dictionary<string, string>? Title { get; set; }

    [JsonPropertyName("description")]
    public Dictionary<string, string>? Description { get; set; }

    [JsonPropertyName("source_url")]
    public string? SourceUrl { get; set; }

    [JsonPropertyName("required_field")]
    public List<string>? RequiredField { get; set; }

    [JsonPropertyName("required_id")]
    public List<int>? RequiredId { get; set; }

    [JsonPropertyName("html_format")]
    public string? HtmlFormat { get; set; }
}
