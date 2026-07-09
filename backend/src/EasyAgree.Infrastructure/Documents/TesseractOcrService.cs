using System.Diagnostics;
using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Infrastructure.Documents;

/// <summary>
/// Shells out to the `tesseract` CLI (installed in the runtime image) -
/// self-hosted, no API key, works offline. Configured for Russian,
/// Uzbek (both scripts), and English since documents mix all three.
/// </summary>
public sealed class TesseractOcrService : IOcrService
{
    private const string Languages = "rus+eng+uzb+uzb_cyrl";

    public async Task<string> ExtractTextAsync(byte[] imageBytes, CancellationToken cancellationToken = default)
    {
        var workDir = Path.Combine(Path.GetTempPath(), "ocr-" + Guid.NewGuid());
        Directory.CreateDirectory(workDir);
        var inputPath = Path.Combine(workDir, "input.png");
        var outputBase = Path.Combine(workDir, "output");

        try
        {
            await File.WriteAllBytesAsync(inputPath, imageBytes, cancellationToken);

            var startInfo = new ProcessStartInfo
            {
                FileName = "tesseract",
                ArgumentList = { inputPath, outputBase, "-l", Languages },
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };

            using var process = Process.Start(startInfo)
                ?? throw new InvalidOperationException("Failed to start tesseract process.");
            await process.WaitForExitAsync(cancellationToken);

            var outputPath = outputBase + ".txt";
            if (process.ExitCode != 0 || !File.Exists(outputPath))
            {
                var stderr = await process.StandardError.ReadToEndAsync(cancellationToken);
                throw new InvalidOperationException($"tesseract failed (exit {process.ExitCode}): {stderr}");
            }

            return await File.ReadAllTextAsync(outputPath, cancellationToken);
        }
        finally
        {
            try { Directory.Delete(workDir, recursive: true); } catch { /* best-effort cleanup */ }
        }
    }
}
