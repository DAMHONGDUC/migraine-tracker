import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/head_region.dart';

/// "Deselect all": empties the location answer from both sides of the head in
/// one tap. The tiles only show the facing side, so clearing them one by one
/// meant turning the head to find the rest.
///
/// **Disabled rather than hidden while nothing is picked**, so the row it sits
/// in keeps its shape — the step is laid out around a head that never moves.
class LocationClearButton extends StatelessWidget {
  const LocationClearButton({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<HeadRegion> selected;
  final ValueChanged<List<HeadRegion>> onChanged;

  void _clear() {
    SdLogger.action(
      LogTagConstant.attackLog,
      'Clear head regions',
      <String, Object?>{'selectedCount': selected.length},
    );
    onChanged(const <HeadRegion>[]);
    SdLogger.info(
      LogTagConstant.attackLog,
      'Head selection cleared',
      <String, Object?>{'selectedCount': 0},
    );
  }

  @override
  Widget build(BuildContext context) => SdButtonV2(
    variant: SdButtonVariantV2.text,
    label: context.l10n.logLocationClearAll,
    onPressed: selected.isEmpty ? null : _clear,
  );
}
