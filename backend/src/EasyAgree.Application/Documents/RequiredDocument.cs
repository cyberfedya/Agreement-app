using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Documents;

/// <summary>
/// One document type it's worth suggesting the user upload for a given
/// template - never an identity document (passport/PINFL/ID) since those
/// come from the account profile / MyID, never from a scan.
/// </summary>
public sealed record RequiredDocument(
    DocumentType Type,
    string Title,
    string Description,
    bool Required,
    int Priority);
