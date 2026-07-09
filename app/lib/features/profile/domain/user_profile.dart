/// The current user's verified identity — what EasyAgree substitutes into
/// agreements as the creator's party details.
class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.passportNumber,
    required this.birthDate,
    required this.address,
    required this.verified,
  });

  final String fullName;
  final String passportNumber;
  final String birthDate;
  final String address;

  /// Whether the identity has been confirmed through MyID.
  final bool verified;
}
