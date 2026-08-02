import 'package:flutter/material.dart';
import 'package:system_design/v2/index.dart';

import '../../domain/enums/head_location.dart';
import 'head_diagram.dart';
import 'location_grid.dart';

/// Second tap: where the pain is. The head diagram up top highlights
/// whichever region is picked from the grid below it; picking only
/// highlights — the app bar's Next confirms and advances. Everything fits
/// on one screen, no scrolling.
class LocationStep extends StatelessWidget {
  const LocationStep({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HeadLocation? selected;
  final ValueChanged<HeadLocation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SdVerticalSpacingV2(xRatio: 2),
        SizedBox(
          height: SdSpacingV2.h200,
          child: HeadDiagram(selected: selected),
        ),
        SdVerticalSpacingV2(xRatio: 2),
        LocationGrid(selected: selected, onSelected: onSelected),
      ],
    );
  }
}
