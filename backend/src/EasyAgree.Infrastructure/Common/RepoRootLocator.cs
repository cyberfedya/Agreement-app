namespace EasyAgree.Infrastructure.Common;

/// <summary>
/// Resolves paths to repo-root-level folders (e.g. "agreements", "ai") that
/// live outside the backend/ tree. Used for local dev, where the folder is
/// found by walking up from the app's base directory; in Docker/production,
/// callers should configure the path explicitly to a mounted volume.
/// </summary>
public static class RepoRootLocator
{
    public static string ResolveFolder(string folderName, string? configuredPath)
    {
        if (!string.IsNullOrWhiteSpace(configuredPath))
            return Path.GetFullPath(configuredPath);

        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        for (var i = 0; i < 10 && dir is not null; i++)
        {
            var candidate = Path.Combine(dir.FullName, folderName);
            if (Directory.Exists(candidate))
                return candidate;
            dir = dir.Parent;
        }

        throw new DirectoryNotFoundException(
            $"Could not locate the '{folderName}' folder by walking up from the app directory. " +
            $"Configure the path explicitly (e.g. via an environment variable pointing at a mounted volume).");
    }
}
