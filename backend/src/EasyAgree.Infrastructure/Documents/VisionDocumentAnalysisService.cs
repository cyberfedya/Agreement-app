using System.Text.Json;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace EasyAgree.Infrastructure.Documents;

/// <summary>
/// One vision-model call per document covers classification, OCR, and
/// semantic field extraction together - a modern multimodal model reads
/// all three off the same image in one pass, so splitting this into three
/// separate round-trips would only add latency and cost.
/// </summary>
public sealed class VisionDocumentAnalysisService(IVisionAiClient visionClient, ILogger<VisionDocumentAnalysisService> logger)
    : IDocumentAnalysisService
{
    private const string SystemPrompt = """
        You are a document intelligence system for a legal-agreement app. Given a photo or scan of one
        document, do three things at once:

        1. Classify the document type - exactly one of: passport, cadastre, technical_passport,
           ownership_certificate, vehicle_registration, vehicle_passport, company_registration,
           tax_certificate, diploma, power_of_attorney, invoice, bank_statement, employment_contract,
           certificate, supporting_document, unknown.
        2. Read the visible text as plain text (OCR), preserving line breaks where reasonable.
        3. Extract every clearly legible fact as semantic key/value pairs, each with a confidence from 0 to 1
           (1.0 = clearly and unambiguously legible, 0.5 = partially legible or inferred, below 0.3 = a guess).
           Use short snake_case English keys describing what the value represents - full_name,
           passport_number, pinfl, birth_date, address, vin, plate_number, brand, model, year,
           cadastre_number, area, rooms, floor, company_name, tin, director, and so on;
           invent a sensible key if none of these fit. Never invent a value that isn't actually visible on
           the document - omit the field entirely instead of guessing.

           Be precise about IDENTIFIERS vs SPECIFICATIONS - these are often confused and are NOT
           interchangeable: engine_number is the serial/ID code stamped on the engine block (e.g.
           "F16D3-987654" or similar alphanumeric code), completely different from engine_capacity/
           engine_type (e.g. "2.0 бензин", "1.6L petrol" - a displacement/fuel description, not an
           identifier). Likewise chassis_number/body_number is a separate stamped serial code, distinct
           from vin (though on some documents they're the same value - only report chassis_number
           separately if the document actually labels it as a distinct field). If a document has an
           engine specification but no visible engine serial number, extract engine_capacity but do NOT
           put the specification under the key engine_number - leave engine_number out entirely rather
           than reporting the wrong kind of value under that key.

        Output ONLY valid JSON, no Markdown, no explanations, matching exactly:
        {"document_type":"<type>","type_confidence":0.0,"ocr_text":"<all visible text>","fields":{"<key>":{"value":"<value>","confidence":0.0}}}
        """;

    private const string UserMessage = "Analyze this document.";

    public async Task<DocumentAnalysisResult> AnalyzeAsync(
        byte[] bytes, string contentType, CancellationToken cancellationToken = default)
    {
        var raw = await visionClient.CompleteWithImageAsync(SystemPrompt, UserMessage, bytes, contentType, cancellationToken);
        return Parse(raw);
    }

    private DocumentAnalysisResult Parse(string raw)
    {
        var json = raw.Trim().Trim('`');
        if (json.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            json = json[4..].TrimStart();

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var type = ParseDocumentType(root.TryGetProperty("document_type", out var typeEl) ? typeEl.GetString() : null);
            var typeConfidence = root.TryGetProperty("type_confidence", out var confEl) && confEl.TryGetDouble(out var conf)
                ? conf
                : 0.0;
            var ocrText = root.TryGetProperty("ocr_text", out var ocrEl) ? ocrEl.GetString() ?? "" : "";

            var fields = new Dictionary<string, ExtractedFieldValue>();
            if (root.TryGetProperty("fields", out var fieldsEl) && fieldsEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in fieldsEl.EnumerateObject())
                {
                    if (prop.Value.ValueKind != JsonValueKind.Object)
                        continue;
                    if (!prop.Value.TryGetProperty("value", out var valueEl) || valueEl.ValueKind != JsonValueKind.String)
                        continue;
                    var value = valueEl.GetString();
                    if (string.IsNullOrWhiteSpace(value))
                        continue;

                    var fieldConfidence = prop.Value.TryGetProperty("confidence", out var fcEl) && fcEl.TryGetDouble(out var fc)
                        ? fc
                        : 0.5;
                    fields[prop.Name] = new ExtractedFieldValue(value, fieldConfidence);
                }
            }

            return new DocumentAnalysisResult(type, typeConfidence, ocrText, fields);
        }
        catch (JsonException ex)
        {
            logger.LogWarning(ex, "Vision model returned unparseable JSON: {Raw}", raw);
            return new DocumentAnalysisResult(DocumentType.Unknown, 0.0, "", new Dictionary<string, ExtractedFieldValue>());
        }
    }

    private static DocumentType ParseDocumentType(string? raw) => raw?.Trim().ToLowerInvariant() switch
    {
        "passport" => DocumentType.Passport,
        "cadastre" => DocumentType.Cadastre,
        "technical_passport" => DocumentType.TechnicalPassport,
        "ownership_certificate" => DocumentType.OwnershipCertificate,
        "vehicle_registration" => DocumentType.VehicleRegistration,
        "vehicle_passport" => DocumentType.VehiclePassport,
        "company_registration" => DocumentType.CompanyRegistration,
        "tax_certificate" => DocumentType.TaxCertificate,
        "diploma" => DocumentType.Diploma,
        "power_of_attorney" => DocumentType.PowerOfAttorney,
        "invoice" => DocumentType.Invoice,
        "bank_statement" => DocumentType.BankStatement,
        "employment_contract" => DocumentType.EmploymentContract,
        "certificate" => DocumentType.Certificate,
        "supporting_document" => DocumentType.SupportingDocument,
        _ => DocumentType.Unknown,
    };
}
