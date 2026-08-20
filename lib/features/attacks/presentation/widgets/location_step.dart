import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../domain/enums/head_region.dart';
import 'head_region_picker.dart';

/// Second tap: where the pain is. The head fills in wherever it is tapped;
/// tapping a filled area clears it again, and the tiles under it do the same
/// by name. Picking only records — the app
/// bar's Next confirms and advances. Everything fits on one screen, no
/// scrolling.
///
/// The one step of the flow that waits for a pick: an attack with no area is
/// not a coarser answer, it is no answer (hard rule 5).
class LocationStep extends StatelessWidget {
  const LocationStep({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<HeadRegion> selected;
  final ValueChanged<List<HeadRegion>> onChanged;

  @override
  Widget build(BuildContext context) {
    // Vertical only. The horizontal gutters belong to the pieces inside,
    // because they do not share one: the tabs and tiles take the step's usual
    // 16, the head takes its own (see HeadRegionPicker).
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h12),
      child: HeadRegionPicker(selected: selected, onChanged: onChanged),
    );
  }
}
