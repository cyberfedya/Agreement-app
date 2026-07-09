import 'package:app/features/profile/domain/user_profile.dart';


abstract class ProfileRepository {
  Future<UserProfile> getCurrent();
}

class DemoProfileRepository implements ProfileRepository {
  const DemoProfileRepository();

  @override
  Future<UserProfile> getCurrent() async => const UserProfile(
    fullName: 'Иванов Иван Иванович',
    passportNumber: 'AD 1234567',
    birthDate: '01.01.1990',
    address: 'г. Ташкент, ул. Примерная, 1',
    verified: true,
  );
}
