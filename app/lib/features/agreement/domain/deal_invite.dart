import 'package:app/l10n/app_localizations.dart';

class DealInvite {
  const DealInvite({
    required this.dealId,
    required this.transactionType,
    required this.firstPartyRole,
    required this.expectedSecondPartyRole,
    required this.invitedBy,
    required this.inviteStatus,
    required this.expiresAt,
  });

  final String dealId;
  final String transactionType;
  final String? firstPartyRole;
  final String? expectedSecondPartyRole;
  final String? invitedBy;
  final String inviteStatus;
  final DateTime? expiresAt;

  factory DealInvite.fromJson(Map<String, dynamic> json) => DealInvite(
    dealId: json['dealId'] as String,
    transactionType: json['transactionType'] as String,
    firstPartyRole: json['firstPartyRole'] as String?,
    expectedSecondPartyRole: json['expectedSecondPartyRole'] as String?,
    invitedBy: json['invitedBy'] as String?,
    inviteStatus: json['inviteStatus'] as String,
    expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
  );
}

/// Translates the backend's stable, language-neutral role codes
/// (seller/buyer/landlord/tenant/...) into the label shown on the invite
/// screen - keep in sync with GenerateFromDealUseCase.RolePairs.
String roleLabel(String? code, AppLocalizations l10n) => switch (code) {
  'seller' => l10n.roleSeller,
  'buyer' => l10n.roleBuyer,
  'landlord' => l10n.roleLandlord,
  'tenant' => l10n.roleTenant,
  'lender' => l10n.roleLender,
  'borrower' => l10n.roleBorrower,
  'employer' => l10n.roleEmployer,
  'employee' => l10n.roleEmployee,
  'customer' => l10n.roleCustomer,
  'contractor' => l10n.roleContractor,
  'donor' => l10n.roleDonor,
  'recipient' => l10n.roleRecipient,
  'first_party' => l10n.roleFirstParty,
  'second_party' => l10n.roleSecondParty,
  _ => l10n.roleParticipant,
};
