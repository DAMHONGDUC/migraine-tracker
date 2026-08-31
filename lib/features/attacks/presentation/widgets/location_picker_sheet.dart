import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/head_region.dart';
import 'head_region_picker.dart';

/// Corrects a logged attack's head areas, with the same picker the log flow's second tap uses.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({required this.selected, super.key});

  final List<HeadRegion> selected;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late List<HeadRegion> _selected = widget.selected;

  /// Keeps the head prominent without hiding the controls below it.
  static double _height(BuildContext context) => math.min(
    MediaQuery.sizeOf(context).height * 0.68,
    SdSpacingConstant.h200 * 2.8,
  );

  @override
  Widget build(BuildContext context) {
    return SdSheetContentV2(
      title: context.l10n.logLocationTitle,
      closeTooltip: context.l10n.commonClose,
      confirmLabel: context.l10n.commonUpdate,
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

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension LocationPickerSheetExt on LocationPickerSheet {
  Future<List<HeadRegion>?> show(BuildContext context) =>
      showSdBottomSheetV2<List<HeadRegion>>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
