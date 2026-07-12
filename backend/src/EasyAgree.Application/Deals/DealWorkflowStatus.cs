namespace EasyAgree.Application.Deals;

public static class DealWorkflowStatus
{
    public const string WaitingForSecondParty = "WAITING_FOR_SECOND_PARTY";
    public const string WaitingForObjectDocument = "WAITING_FOR_OBJECT_DOCUMENT";
    public const string MissingMandatoryTerms = "MISSING_MANDATORY_TERMS";
    public const string WaitingForPartyAgreement = "WAITING_FOR_PARTY_AGREEMENT";
    public const string LegalReviewRequired = "LEGAL_REVIEW_REQUIRED";
    public const string ReadyToGenerate = "READY_TO_GENERATE";
}
