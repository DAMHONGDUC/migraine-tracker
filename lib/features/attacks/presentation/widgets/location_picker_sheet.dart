import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import '../../domain/enums/head_location.dart';
import 'location_grid.dart';

/// Corrects a logged attack's head location, with the same tile grid the
/// log flow's second tap uses. Picking IS the answer — the tap pops the
/// choice, exactly as it advances the log flow — so there is no Save.
///
/// Pops the picked location, or null when dismissed.
class LocationPickerSheet extends StatelessWidget {
  const LocationPickerSheet({required this.selected, super.key});

  final HeadLocation selected;

  @override
  Widget build(BuildContext context) {
    return AppSheetContent(
      title: context.l10n.logLocationTitle,
      child: LocationGrid(
        selected: selected,
        onSelected: (HeadLocation location) =>
            Navigator.of(context).pop(location),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension LocationPickerSheetExt on LocationPickerSheet {
  Future<HeadLocation?> show(BuildContext context) =>
      showAppBottomSheet<HeadLocation>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
