import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/permission_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/agreement/domain/agreement_qr.dart';
import 'package:app/l10n/app_localizations.dart';

/// Camera QR scanner for the second party: scan the first party's QR code
/// to open [AppRoutes.dealInvite] for that deal.
class QrPage extends StatefulWidget {
  const QrPage({super.key, this.permissionService});

  final PermissionService? permissionService;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late final PermissionService _permissions = widget.permissionService ?? DevicePermissionService();
  final MobileScannerController _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _handled = false;
  bool _checkingPermission = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _permissions.requestCamera();
    if (!mounted) return;
    setState(() {
      _checkingPermission = false;
      _permissionDenied = !granted;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    final key = extractAgreementKey(raw);
    if (key == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.qrNotAgreementCode)),
      );
      return;
    }

    _handled = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dealInvite, arguments: key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.qrTitle),
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : _permissionDenied
          ? _PermissionDeniedView(onRetry: _checkPermission)
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: Corners.lgRadius,
                    ),
                  ),
                ),
                Positioned(
                  bottom: Insets.x40,
                  left: Insets.x24,
                  right: Insets.x24,
                  child: Text(
                    l10n.qrHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 40),
            const SizedBox(height: Insets.x16),
            Text(
              l10n.qrCameraPermissionNeeded,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: Insets.x20),
            FilledButton(onPressed: onRetry, child: Text(l10n.qrAllowAccess)),
          ],
        ),
      ),
    );
  }
}
