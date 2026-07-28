import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_sheet_content.dart';
import '../../../../core/widgets/app_sheet_header.dart';
import '../../domain/enums/head_location.dart';
import 'location_grid.dart';

/// Corrects a logged attack's head location, with the same tile grid the log
/// flow's second tap uses.
///
/// A tap only moves the highlight: unlike the log flow, where picking IS
/// advancing, here the sheet is editing something that already has a value,
/// so it waits for the tick. The X leaves it as it was.
///
/// Pops the picked location, or null when dismissed.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({required this.selected, super.key});

  final HeadLocation selected;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late HeadLocation _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return AppSheetContent(
      title: context.l10n.logLocationTitle,
      action: AppSheetAction.edit,
      onConfirm: () => Navigator.of(context).pop(_selected),
      child: LocationGrid(
        selected: _selected,
        onSelected: (HeadLocation location) =>
            setState(() => _selected = location),
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
