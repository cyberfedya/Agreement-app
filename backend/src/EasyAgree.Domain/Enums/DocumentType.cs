namespace EasyAgree.Domain.Enums;

public enum DocumentType
{
    Unknown = 0,
    Passport = 1,
    Cadastre = 2,
    TechnicalPassport = 3,
    OwnershipCertificate = 4,
    VehicleRegistration = 5,
    VehiclePassport = 6,
    CompanyRegistration = 7,
    TaxCertificate = 8,
    Diploma = 9,
    PowerOfAttorney = 10,
    Invoice = 11,
    BankStatement = 12,
    EmploymentContract = 13,
    Certificate = 14,

    /// <summary>Catch-all for useful-but-narrow categories (floor plans, estimates, drawings,
    /// insurance policies, inspection reports, inheritance certificates, court filings, utility
    /// documentation) that don't warrant their own enum value.</summary>
    SupportingDocument = 15,
}
