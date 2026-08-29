import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../domain/enums/head_region.dart';
import 'head_region_picker.dart';

/// Second tap: where the pain is.
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
    // Vertical only.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h12),
      child: HeadRegionPicker(selected: selected, onChanged: onChanged),
    );
  }
}
