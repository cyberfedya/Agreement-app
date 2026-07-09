using EasyAgree.Application.Common.Interfaces;
using OpenAI.Chat;

namespace EasyAgree.Infrastructure.AI;

/// <summary>Talks to the connected OpenAI-compatible inference server's multimodal endpoint.</summary>
public sealed class VllmVisionClient(ChatClient chatClient) : IVisionAiClient
{
    public async Task<string> CompleteWithImageAsync(
        string systemPrompt, string userMessage, byte[] imageBytes, string contentType,
        CancellationToken cancellationToken = default)
    {
        var userContent = ChatMessageContentPart.CreateTextPart(userMessage);
        var imageContent = ChatMessageContentPart.CreateImagePart(BinaryData.FromBytes(imageBytes), contentType);

        var completion = await chatClient.CompleteChatAsync(
            [
                new SystemChatMessage(systemPrompt),
                new UserChatMessage(userContent, imageContent),
            ],
            cancellationToken: cancellationToken);

        return completion.Value.Content[0].Text;
    }
}
