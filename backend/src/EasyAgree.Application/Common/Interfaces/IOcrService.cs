namespace EasyAgree.Application.Common.Interfaces;

/// <summary>Pulls raw text off an image - no interpretation, just characters.</summary>
public interface IOcrService
{
    Task<string> ExtractTextAsync(byte[] imageBytes, CancellationToken cancellationToken = default);
}
