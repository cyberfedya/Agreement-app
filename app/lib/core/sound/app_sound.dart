import 'package:app/core/sound/sound_settings_provider.dart';

/// One short interface sound. Each is tagged with the minimum [SoundLevel]
/// it plays at - the fine-grained per-field/per-stage sounds only play at
/// [SoundLevel.extended]; the "important event" sounds already play at
/// [SoundLevel.minimal] (the default).
enum AppSound {
  /// One field just got auto-filled (OCR or a voice/typed answer).
  tick('tick', SoundLevel.extended),

  /// One interview stage just completed.
  stageComplete('stage_complete', SoundLevel.extended),

  /// A document/answer conflict was just found - a nudge, not an alarm.
  attention('attention', SoundLevel.minimal),

  /// A document finished verifying successfully.
  documentVerified('document_verified', SoundLevel.minimal),

  /// The agreement was successfully generated - the app's signature sound.
  dealCreated('deal_created', SoundLevel.minimal),

  /// The second party joined (accepted the invite) or signed.
  partyJoined('party_joined', SoundLevel.minimal),

  /// Something failed - calm, never alarming.
  error('error', SoundLevel.minimal);

  const AppSound(this.assetName, this.minimumLevel);

  final String assetName;
  final SoundLevel minimumLevel;

  String get assetPath => 'assets/sounds/$assetName.wav';
}
