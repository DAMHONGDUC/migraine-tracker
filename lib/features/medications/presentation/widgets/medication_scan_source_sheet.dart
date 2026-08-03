import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/services/medication_photo_source.dart';

/// Where the label photo should come from. Pops the chosen origin, or null
/// when the sheet is dismissed.
class MedicationScanSourceSheet extends StatelessWidget {
  const MedicationScanSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const SdIconV2(icon: Icons.photo_camera_outlined),
            title: Text(
              context.l10n.medicationScanCamera,
              style: AppTextStyle.bodyLarge,
            ),
            onTap: () =>
                Navigator.of(context).pop(MedicationPhotoOrigin.camera),
          ),
          ListTile(
            leading: const SdIconV2(icon: Icons.photo_library_outlined),
            title: Text(
              context.l10n.medicationScanGallery,
              style: AppTextStyle.bodyLarge,
            ),
            onTap: () =>
                Navigator.of(context).pop(MedicationPhotoOrigin.gallery),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension MedicationScanSourceSheetExt on MedicationScanSourceSheet {
  Future<MedicationPhotoOrigin?> show(BuildContext context) =>
      showSdBottomSheetV2<MedicationPhotoOrigin>(context, builder: (_) => this);
}
