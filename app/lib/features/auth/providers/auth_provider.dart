import 'package:app/features/auth/data/auth_repository.dart';

/// Scaffold for the V2 auth feature (MyID). Not wired into routing yet.
class AuthProvider {
  AuthProvider(this.repository);

  final AuthRepository repository;
}
