/// The user's self-entered identity — what EasyAgree substitutes into
/// agreements as the creator's party details. There is no verification
/// step yet (MyID login is a demo gate, not a data source); the value here
/// is exactly what the user typed into the Profile screen.
class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.passportNumber,
    required this.birthDate,
    required this.address,
  });

  final String fullName;
  final String passportNumber;
  final String birthDate;
  final String address;

  static const empty = UserProfile(fullName: '', passportNumber: '', birthDate: '', address: '');

  bool get isEmpty => fullName.isEmpty && passportNumber.isEmpty && birthDate.isEmpty && address.isEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    fullName: json['fullName'] as String? ?? '',
    passportNumber: json['passportNumber'] as String? ?? '',
    birthDate: json['birthDate'] as String? ?? '',
    address: json['address'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'passportNumber': passportNumber,
    'birthDate': birthDate,
    'address': address,
  };
}
