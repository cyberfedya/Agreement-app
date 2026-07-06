import 'package:app/features/auth/domain/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> loginWithMyId(String token);
}
