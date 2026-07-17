import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/features/documents/presentation/widgets/camera_capture_sheet.dart';

/// Picks document photos for [source]: gallery keeps using the OS's own
/// native multi-select (`pickMultiImage`), unchanged; camera routes through
/// [CameraCaptureSheet] so the user can take as many pages as they need,
/// retake or delete any of them, then confirm the whole batch at once -
/// instead of being limited to a single photo per attempt.
Future<List<XFile>> pickDocumentFiles(BuildContext context, ImageSource source) {
  if (source == ImageSource.gallery) {
    return ImagePicker().pickMultiImage(imageQuality: 85);
  }
  return CameraCaptureSheet.show(context);
}
