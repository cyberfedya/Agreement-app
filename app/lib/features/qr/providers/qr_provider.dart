import 'package:app/core/services/qr_service.dart';

/// Scaffold for the V2 QR feature. Not wired into routing yet.
class QrProvider {
  QrProvider(this.service);

  final QrService service;
}
