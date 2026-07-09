namespace EasyAgree.Application.Common.Interfaces;

/// <summary>Thin abstraction over the connected LLM's multimodal (image + text) capability.</summary>
public interface IVisionAiClient
{
    Task<string> CompleteWithImageAsync(
        string systemPrompt, string userMessage, byte[] imageBytes, string contentType,
        CancellationToken cancellationToken = default);
}
