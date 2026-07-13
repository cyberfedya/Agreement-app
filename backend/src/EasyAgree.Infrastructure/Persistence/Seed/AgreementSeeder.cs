using System.Diagnostics;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;
using EasyAgree.Infrastructure.Common;
using EasyAgree.Infrastructure.Persistence.Seed.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EasyAgree.Infrastructure.Persistence.Seed;

/// <summary>
/// Imports agreement JSON files (the source of truth on disk) into PostgreSQL.
/// Idempotent: re-running upserts by Key without creating duplicates, and never
/// deletes a template that no longer has a matching file.
/// </summary>
public sealed class AgreementSeeder(
    EasyAgreeDbContext db,
    AgreementJsonLoader loader,
    IOptions<AgreementSeederOptions> options,
    ILogger<AgreementSeeder> logger)
{
    private readonly AgreementSeederOptions _options = options.Value;

    public async Task<AgreementSeedResult> SeedAsync(CancellationToken cancellationToken = default)
    {
        var stopwatch = Stopwatch.StartNew();
        var result = new AgreementSeedResult();

        var sourcePath = RepoRootLocator.ResolveFolder("agreements", _options.SourcePath);
        logger.LogInformation("Agreement seeder starting. Source folder: {SourcePath}", sourcePath);

        var files = loader.DiscoverFiles(sourcePath);
        result.TotalFilesScanned = files.Count;
        logger.LogInformation("Discovered {Count} agreement JSON files", files.Count);

        var existingByKey = await db.AgreementTemplates
            .Include(t => t.Translations)
            .Include(t => t.Fields)
            .ToDictionaryAsync(t => t.Key, StringComparer.Ordinal, cancellationToken);

        var seenKeys = new HashSet<string>(StringComparer.Ordinal);
        var pendingSinceLastSave = 0;

        await foreach (var item in loader.LoadAsync(files, cancellationToken))
        {
            if (!item.IsSuccess)
            {
                result.Errors++;
                logger.LogWarning("Skipping invalid agreement file {File}: {Reason}", item.FilePath, item.Error);
                continue;
            }

            var model = item.Model!;
            var key = model.Key!;

            if (!seenKeys.Add(key))
            {
                result.Skipped++;
                logger.LogWarning(
                    "Duplicate agreement key '{Key}' found in {File}; keeping the first occurrence and skipping this file",
                    key, item.FilePath);
                continue;
            }

            if (existingByKey.TryGetValue(key, out var template))
            {
                UpdateTemplate(template, model);
                result.Updated++;
            }
            else
            {
                template = CreateTemplate(model);
                db.AgreementTemplates.Add(template);
                existingByKey[key] = template;
                result.Imported++;
            }

            pendingSinceLastSave++;
            if (pendingSinceLastSave >= _options.BatchSize)
            {
                await db.SaveChangesAsync(cancellationToken);
                db.ChangeTracker.Clear();
                pendingSinceLastSave = 0;
            }
        }

        if (pendingSinceLastSave > 0)
            await db.SaveChangesAsync(cancellationToken);

        result.TotalTemplatesInDatabase = await db.AgreementTemplates.CountAsync(cancellationToken);
        stopwatch.Stop();
        result.Elapsed = stopwatch.Elapsed;

        LogSummary(result);
        return result;
    }

    private static AgreementTemplate CreateTemplate(AgreementJsonModel model)
    {
        var now = DateTime.UtcNow;
        var template = new AgreementTemplate
        {
            Id = Guid.NewGuid(),
            Domain = model.Domain!,
            Key = model.Key!,
            SourceUrl = model.SourceUrl,
            HtmlTemplate = model.HtmlFormat!,
            IsActive = true,
            Version = 1,
            CreatedAt = now,
            UpdatedAt = now
        };

        foreach (var (language, title, description) in BuildTranslations(model))
        {
            template.Translations.Add(new AgreementTemplateTranslation
            {
                Id = Guid.NewGuid(),
                Language = language,
                Title = title,
                Description = description
            });
        }

        foreach (var fieldId in DistinctFieldIds(model))
        {
            template.Fields.Add(new AgreementTemplateField
            {
                Id = Guid.NewGuid(),
                FieldId = fieldId,
                Mode = AgreementFieldMode.Required
            });
        }

        return template;
    }

    private void UpdateTemplate(AgreementTemplate template, AgreementJsonModel model)
    {
        template.Domain = model.Domain!;
        template.SourceUrl = model.SourceUrl;
        template.HtmlTemplate = model.HtmlFormat!;
        template.UpdatedAt = DateTime.UtcNow;
        template.Version += 1;

        SyncTranslations(template, model);
        SyncFields(template, model);
    }

    private void SyncTranslations(AgreementTemplate template, AgreementJsonModel model)
    {
        var remaining = template.Translations.ToDictionary(t => t.Language, StringComparer.OrdinalIgnoreCase);

        foreach (var (language, title, description) in BuildTranslations(model))
        {
            if (remaining.Remove(language, out var translation))
            {
                translation.Title = title;
                translation.Description = description;
            }
            else
            {
                var added = new AgreementTemplateTranslation
                {
                    Id = Guid.NewGuid(),
                    Language = language,
                    Title = title,
                    Description = description
                };
                template.Translations.Add(added);
                // The Id is client-generated (a fresh Guid), not database-
                // generated, so EF's automatic change detection cannot tell
                // from the key value alone that this is a brand new row -
                // for a template with enough existing children, it has
                // occasionally inferred Modified instead of Added and then
                // failed with a DbUpdateConcurrencyException ("expected 1
                // row, affected 0") since no such row exists yet. Setting
                // the state explicitly removes the ambiguity.
                db.Entry(added).State = EntityState.Added;
            }
        }

        foreach (var stale in remaining.Values)
        {
            template.Translations.Remove(stale);
            db.AgreementTemplateTranslations.Remove(stale);
        }
    }

    private void SyncFields(AgreementTemplate template, AgreementJsonModel model)
    {
        var remaining = template.Fields.ToDictionary(f => f.FieldId);

        foreach (var fieldId in DistinctFieldIds(model))
        {
            if (remaining.Remove(fieldId, out var field))
            {
                field.Mode = AgreementFieldMode.Required;
            }
            else
            {
                var added = new AgreementTemplateField
                {
                    Id = Guid.NewGuid(),
                    FieldId = fieldId,
                    Mode = AgreementFieldMode.Required
                };
                template.Fields.Add(added);
                // See the matching comment in SyncTranslations - same
                // client-generated-key ambiguity, same fix.
                db.Entry(added).State = EntityState.Added;
            }
        }

        foreach (var stale in remaining.Values)
        {
            template.Fields.Remove(stale);
            db.AgreementTemplateFields.Remove(stale);
        }
    }

    private static IEnumerable<int> DistinctFieldIds(AgreementJsonModel model) =>
        (model.RequiredId ?? []).Distinct();

    private static IEnumerable<(string Language, string Title, string Description)> BuildTranslations(AgreementJsonModel model)
    {
        var titles = model.Title ?? [];
        var descriptions = model.Description ?? [];
        var languages = titles.Keys.Union(descriptions.Keys, StringComparer.OrdinalIgnoreCase);

        foreach (var language in languages)
        {
            titles.TryGetValue(language, out var title);
            descriptions.TryGetValue(language, out var description);
            yield return (language, title ?? string.Empty, description ?? string.Empty);
        }
    }

    private void LogSummary(AgreementSeedResult result)
    {
        logger.LogInformation(
            "Agreement seeding complete in {ElapsedMs}ms. Scanned={Scanned} Imported={Imported} Updated={Updated} Skipped={Skipped} Errors={Errors} TotalInDatabase={Total}",
            result.Elapsed.TotalMilliseconds,
            result.TotalFilesScanned,
            result.Imported,
            result.Updated,
            result.Skipped,
            result.Errors,
            result.TotalTemplatesInDatabase);
    }
}
