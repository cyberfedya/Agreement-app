// Dev-only generator - not part of the runtime app. Run once with
// `dart run tool/generate_sounds.dart` to (re)produce assets/sounds/*.wav.
//
// Synthesizes short, calm sine-tone UI sounds (16-bit PCM mono WAV) with a
// linear fade envelope so nothing clicks/pops - no external audio tools or
// packages needed, just dart:io.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int _sampleRate = 44100;

void main() {
  final dir = Directory('assets/sounds')..createSync(recursive: true);

  _write('${dir.path}/tick.wav', _tone([(880, 50)], fadeMs: 8));
  _write('${dir.path}/stage_complete.wav', _tone([(659, 90), (880, 110)], fadeMs: 12));
  _write('${dir.path}/attention.wav', _tone([(523, 150)], fadeMs: 20));
  _write('${dir.path}/document_verified.wav', _tone([(784, 110), (988, 140)], fadeMs: 15));
  _write('${dir.path}/deal_created.wav', _tone([(523, 90), (659, 90), (784, 90), (1047, 130)], fadeMs: 12));
  _write('${dir.path}/party_joined.wav', _tone([(740, 90), (880, 110)], fadeMs: 12));
  _write('${dir.path}/error.wav', _tone([(330, 150)], fadeMs: 25));

  stdout.writeln('Generated 7 sounds in ${dir.path}');
}

/// One or more (frequencyHz, durationMs) notes played back to back, each
/// with its own short fade-in/out envelope so consecutive notes never pop.
Float64List _tone(List<(double freq, int durationMs)> notes, {required int fadeMs}) {
  final samples = <double>[];
  for (final (freq, durationMs) in notes) {
    final n = (_sampleRate * durationMs / 1000).round();
    final fadeSamples = (_sampleRate * fadeMs / 1000).round();
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      var amplitude = 0.5;
      if (i < fadeSamples) amplitude *= i / fadeSamples;
      if (i > n - fadeSamples) amplitude *= (n - i) / fadeSamples;
      samples.add(amplitude * sin(2 * pi * freq * t));
    }
  }
  return Float64List.fromList(samples);
}

void _write(String path, Float64List samples) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
  }
  final dataBytes = pcm.buffer.asUint8List();
  final byteRate = _sampleRate * 2;
  final blockAlign = 2;

  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_uint32le(36 + dataBytes.length))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_uint32le(16))
    ..add(_uint16le(1)) // PCM
    ..add(_uint16le(1)) // mono
    ..add(_uint32le(_sampleRate))
    ..add(_uint32le(byteRate))
    ..add(_uint16le(blockAlign))
    ..add(_uint16le(16)) // bits per sample
    ..add('data'.codeUnits)
    ..add(_uint32le(dataBytes.length));

  final file = File(path);
  file.writeAsBytesSync(header.toBytes() + dataBytes);
}

List<int> _uint32le(int value) => [
  value & 0xFF,
  (value >> 8) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 24) & 0xFF,
];

List<int> _uint16le(int value) => [value & 0xFF, (value >> 8) & 0xFF];
