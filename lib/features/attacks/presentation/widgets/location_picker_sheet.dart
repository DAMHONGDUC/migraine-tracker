import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/head_region.dart';
import 'head_region_picker.dart';

/// Corrects a logged attack's head areas, with the same picker the log
/// flow's second tap uses.
///
/// A tap only moves the fill: unlike the log flow, where picking IS
/// advancing, here the sheet is editing something that already has a value,
/// so it waits for the tick. The X leaves it as it was.
///
/// Pops the picked areas, or null when dismissed. Never pops an empty list —
/// the tick is disarmed while nothing is picked, because an attack with no
/// area cannot be saved (hard rule 5).
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({required this.selected, super.key});

  final List<HeadRegion> selected;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late List<HeadRegion> _selected = widget.selected;

  /// Tall enough that the head is the sheet's subject rather than a stamp at
  /// the top of it, and short enough to leave the tabs, the area tiles and
  /// the summary in view without scrolling.
  ///
  /// A fraction of the screen with a ceiling, not a fixed number: the picker
  /// grew a grid of eleven tiles under the head, and a constant tall enough
  /// to seat those on a 852pt phone is taller than a 667pt one has to give.
  static double _height(BuildContext context) => math.min(
    MediaQuery.sizeOf(context).height * 0.68,
    SdSpacingConstant.h200 * 2.8,
  );

  @override
  Widget build(BuildContext context) {
    return SdSheetContentV2(
      title: context.l10n.logLocationTitle,
      closeTooltip: context.l10n.commonClose,
      confirmTooltip: context.l10n.commonDone,
      action: SdSheetActionV2.edit,
      onConfirm: _selected.isEmpty
          ? null
          : () => Navigator.of(context).pop(_selected),
      child: SizedBox(
        height: _height(context),
        child: HeadRegionPicker(
          selected: _selected,
          onChanged: (List<HeadRegion> regions) =>
              setState(() => _selected = regions),
        ),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension LocationPickerSheetExt on LocationPickerSheet {
  Future<List<HeadRegion>?> show(BuildContext context) =>
      showSdBottomSheetV2<List<HeadRegion>>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
