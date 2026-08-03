import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';

/// Which way the user wants to add a medication.
enum MedicationAddMode {
  /// Name only, in a dialog — the fast path, and what the log flow uses.
  quick,

  /// The full form: name plus whatever the box says, and the label scan.
  detailed,
}

/// Offers the two ways in. Pops the chosen mode, or null when dismissed.
class MedicationAddSheet extends StatelessWidget {
  const MedicationAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const SdIconV2(icon: Icons.bolt_outlined),
            title: Text(
              context.l10n.medicationAddQuick,
              style: AppTextStyle.bodyLarge,
            ),
            subtitle: Text(
              context.l10n.medicationAddQuickBody,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            onTap: () => Navigator.of(context).pop(MedicationAddMode.quick),
          ),
          ListTile(
            leading: const SdIconV2(icon: Icons.notes_outlined),
            title: Text(
              context.l10n.medicationAddDetailed,
              style: AppTextStyle.bodyLarge,
            ),
            subtitle: Text(
              context.l10n.medicationAddDetailedBody,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            onTap: () => Navigator.of(context).pop(MedicationAddMode.detailed),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension MedicationAddSheetExt on MedicationAddSheet {
  Future<MedicationAddMode?> show(BuildContext context) =>
      showSdBottomSheetV2<MedicationAddMode>(context, builder: (_) => this);
}
