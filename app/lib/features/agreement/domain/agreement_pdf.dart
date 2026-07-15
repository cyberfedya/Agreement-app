import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/l10n/app_localizations.dart';

/// Renders the agreement HTML to a PDF (via the platform's native HTML
/// renderer, so tables/formatting match what's shown on screen) and opens
/// the OS share sheet so the user can save or send it.
Future<void> exportAgreementAsPdf(BuildContext context, String html) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // ignore: deprecated_member_use
    final bytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: '<html><body>${sanitizeAgreementHtml(html)}</body></html>',
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await Printing.sharePdf(bytes: bytes, filename: 'agreement.pdf');
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.agreementPdfExportFailed)),
    );
  }
}
