import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../domain/enums/head_region.dart';
import 'head_diagram.dart';
import 'head_region_picker.dart';

/// Second tap: where the pain is.
///
/// Also what `LocationPickerSheet` shows when an already-logged attack's
/// areas are corrected, so the two read identically — the step owns the
/// gutters and the air around the head, and the sheet only wraps it.
class LocationStep extends StatelessWidget {
  const LocationStep({
    required this.selected,
    required this.onChanged,
    this.headLoadAfter = Duration.zero,
    super.key,
  });

  final List<HeadRegion> selected;
  final ValueChanged<List<HeadRegion>> onChanged;

  /// See [HeadDiagram.loadAfter].
  final Duration headLoadAfter;

  @override
  Widget build(BuildContext context) {
    // Vertical only: [HeadRegionPicker] pads its own tabs and tiles, and
    // insets the head further than the gutter, so the sides are its business.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h12),
      child: HeadRegionPicker(
        selected: selected,
        onChanged: onChanged,
        headLoadAfter: headLoadAfter,
      ),
    );
  }
}
