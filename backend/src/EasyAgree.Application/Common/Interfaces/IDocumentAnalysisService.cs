using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Common.Interfaces;

/// <summary>
/// A single vision-model pass over one uploaded file: classifies what kind
/// of document it is, reads its text, and extracts whatever semantic
/// fields are visible - one call covers classification, OCR, and
/// extraction together (see <see cref="DocumentAnalysisResult"/>).
/// </summary>
public interface IDocumentAnalysisService
{
    Task<DocumentAnalysisResult> AnalyzeAsync(
        byte[] bytes, string contentType, CancellationToken cancellationToken = default);
}
