import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/head_region.dart';
import 'location_clear_button.dart';
import 'location_step.dart';

/// Corrects a logged attack's head areas.
///
/// **It shows [LocationStep] itself, not another arrangement of the picker.**
/// Correcting a location and picking one are the same job, so the only
/// difference between the two is the sheet around it: the step keeps its own
/// gutters and its own air above and below the head, and the sheet hands it
/// the full width (`contentHorizontalPadding: 0`) instead of adding a second
/// gutter on top of the step's.
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

  void _onChanged(List<HeadRegion> regions) =>
      setState(() => _selected = regions);

  @override
  Widget build(BuildContext context) {
    return SdSheetContentV2(
      title: context.l10n.logLocationTitle,
      closeTooltip: context.l10n.commonClose,
      confirmLabel: context.l10n.commonUpdate,
      onConfirm: _selected.isEmpty
          ? null
          : () => Navigator.of(context).pop(_selected),
      contentHorizontalPadding: 0,
      // Nothing here scrolls, and that is not a preference: the picker's own
      // rule is that the whole step renders on one screen, and on iOS a scroll
      // view rubber-bands even when its content fits — so a drag that turns
      // the head bounced the sheet's content on the same finger.
      scrollable: false,
      child: SizedBox(
        height: _height(context),
        // Deselect all sits under the step, where the flow puts it beside
        // Save now; the sheet's own Update is in the header.
        child: Column(
          children: <Widget>[
            Expanded(
              child: LocationStep(selected: _selected, onChanged: _onChanged),
            ),
            LocationClearButton(selected: _selected, onChanged: _onChanged),
          ],
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
        // The head is dragged to turn it, and the sheet read the same drag as
        // a dismissal — turning the head pulled the sheet down under the
        // finger. Tapping outside and the header's X are the ways out; the
        // drag handle goes with the swipe it promised.
        draggable: false,
        builder: (_) => this,
      );
}
