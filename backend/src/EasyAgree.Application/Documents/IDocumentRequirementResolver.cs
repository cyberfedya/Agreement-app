namespace EasyAgree.Application.Documents;

public interface IDocumentRequirementResolver
{
    /// <summary>
    /// Which document types are worth suggesting the user upload for this
    /// template - empty when nothing useful comes to mind, in which case
    /// the upload step is skipped and the interview starts normally.
    /// </summary>
    IReadOnlyList<RequiredDocument> Resolve(string templateKey, string templateTitle);
}
