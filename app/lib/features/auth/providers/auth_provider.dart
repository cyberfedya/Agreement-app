import 'package:app/features/auth/data/auth_repository.dart';

class AuthProvider {
  AuthProvider(this._repository);

  final AuthRepository _repository;
}
