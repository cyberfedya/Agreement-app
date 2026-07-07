using System.Net;
using System.Text.RegularExpressions;

namespace EasyAgree.Application.Common;

/// <summary>
/// Reads and fills the "{#fieldId}label" placeholders embedded in an
/// agreement's html_format. This is the single place that understands the
/// placeholder syntax — both question labels and answer substitution go
/// through here so the two can never drift apart.
/// </summary>
public static partial class AgreementPlaceholderParser
{
    [GeneratedRegex(@"\{#(\d+)\}([^<]*)")]
    private static partial Regex PlaceholderRegex();

    /// <summary>Maps each fieldId to the label text that follows its first non-blank occurrence.</summary>
    public static IReadOnlyDictionary<int, string> ExtractLabels(string html)
    {
        var labels = new Dictionary<int, string>();

        foreach (Match match in PlaceholderRegex().Matches(html))
        {
            var fieldId = int.Parse(match.Groups[1].Value);
            var label = match.Groups[2].Value.Trim();

            if (!labels.TryGetValue(fieldId, out var existing) || (string.IsNullOrEmpty(existing) && label.Length > 0))
                labels[fieldId] = label;
        }

        return labels;
    }

    /// <summary>Replaces every "{#fieldId}label" occurrence with the HTML-encoded answer for that field.</summary>
    public static string ReplacePlaceholders(string html, IReadOnlyDictionary<int, string> answers)
    {
        return PlaceholderRegex().Replace(html, match =>
        {
            var fieldId = int.Parse(match.Groups[1].Value);
            return answers.TryGetValue(fieldId, out var answer)
                ? WebUtility.HtmlEncode(answer)
                : match.Value;
        });
    }
}
