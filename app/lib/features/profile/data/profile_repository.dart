import 'package:uuid/uuid.dart';

import 'package:app/core/network/api_exception.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/features/profile/domain/user_profile.dart';

/// Source of the current user's identity, keyed by a stable id generated
/// once per install (there is no account/auth system yet — see
/// [ApiProfileRepository.getProfileId]). A real MyID integration would
/// replace the id source and nothing else in the app.
abstract class ProfileRepository {
  /// The stable id this device's profile (and every deal it creates) is
  /// filed under. Generated once and persisted locally.
  Future<String> getProfileId();

  /// Null means the user hasn't filled in their profile yet.
  Future<UserProfile?> getCurrent();

  Future<UserProfile> save(UserProfile profile);

  Future<void> delete();
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api, this._storage);

  static const _profileIdKey = 'profile_id';

  final ApiService _api;
  final LocalStorage _storage;

  @override
  Future<String> getProfileId() async {
    final existing = await _storage.read(_profileIdKey);
    if (existing != null) return existing;

    final generated = const Uuid().v4();
    await _storage.write(_profileIdKey, generated);
    return generated;
  }

  @override
  Future<UserProfile?> getCurrent() async {
    try {
      return await _api.getProfile(await getProfileId());
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<UserProfile> save(UserProfile profile) async => _api.saveProfile(await getProfileId(), profile);

  @override
  Future<void> delete() async {
    await _api.deleteProfile(await getProfileId());
    await _storage.delete(_profileIdKey);
  }
}
