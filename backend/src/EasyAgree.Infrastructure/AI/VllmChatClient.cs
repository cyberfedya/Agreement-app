using EasyAgree.Application.Common.Interfaces;
using OpenAI.Chat;

namespace EasyAgree.Infrastructure.AI;

/// <summary>Talks to the connected OpenAI-compatible inference server (vLLM).</summary>
public sealed class VllmChatClient(ChatClient chatClient) : IAiChatClient
{
    public async Task<string> CompleteAsync(
        string systemPrompt, string userMessage, CancellationToken cancellationToken = default)
    {
        var completion = await chatClient.CompleteChatAsync(
            [new SystemChatMessage(systemPrompt), new UserChatMessage(userMessage)],
            cancellationToken: cancellationToken);

        return completion.Value.Content[0].Text;
    }
}
