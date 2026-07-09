using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

/// <summary>
/// What a vision pass over one uploaded file produced: what kind of
/// document it is, the raw text on it, and whatever semantic fields could
/// be read off it. Classification, OCR and field extraction all come from
/// a single model call - a modern vision-capable model reads all three at
/// once from the same image, so splitting it into three separate calls
/// would only add latency and cost for no accuracy benefit.
/// </summary>
public sealed record DocumentAnalysisResult(
    DocumentType Type,
    double TypeConfidence,
    string OcrText,
    IReadOnlyDictionary<string, ExtractedFieldValue> Fields);
