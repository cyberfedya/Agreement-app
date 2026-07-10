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
String roleLabel(String? code) => switch (code) {
  'seller' => 'Продавец',
  'buyer' => 'Покупатель',
  'landlord' => 'Арендодатель',
  'tenant' => 'Арендатор',
  'lender' => 'Займодавец',
  'borrower' => 'Заёмщик',
  'employer' => 'Работодатель',
  'employee' => 'Работник',
  'customer' => 'Заказчик',
  'contractor' => 'Исполнитель',
  'donor' => 'Даритель',
  'recipient' => 'Одаряемый',
  'first_party' => 'Первая сторона',
  'second_party' => 'Вторая сторона',
  _ => 'Участник сделки',
};
