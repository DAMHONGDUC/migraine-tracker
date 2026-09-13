import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/attack_duration_constant.dart';
import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import 'attack_option_tile.dart';

/// Records how long an attack lasted, after the fact.
class AttackDurationSheet extends StatelessWidget {
  const AttackDurationSheet({
    required this.startedAt,
    required this.endedAt,
    super.key,
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  Duration? get _selected => endedAt?.difference(startedAt);

  void _pick(BuildContext context, Duration duration) =>
      Navigator.of(context).pop((endedAt: startedAt.add(duration)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Duration sinceStart = DateTime.now().toUtc().difference(startedAt);

    return SdSheetContentV2(
      title: l10n.attackDurationSheetTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The common case for an attack still running: the user is looking at the app because it has just stopped.
          if (!sinceStart.isNegative)
            SizedBox(
              // The same box the grid gives every other option: left to size itself it shrank to its line of text, a thin pill above ten chunky tiles.
              height: AttackOptionTile.height,
              child: AttackOptionTile(
                label: l10n.attackDurationEndedNow,
                detail: sinceStart.label(l10n),
                selected: false,
                onTap: () => _pick(context, sinceStart),
              ),
            ),
          SizedBox(height: SdSpacingConstant.h8),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // The sheet owns the scrolling.
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LogFlowConstant.optionsPerRow,
              mainAxisSpacing: SdSpacingConstant.h8,
              crossAxisSpacing: SdSpacingConstant.w8,
              mainAxisExtent: AttackOptionTile.height,
            ),
            itemCount: AttackDurationConstant.options.length,
            itemBuilder: (BuildContext context, int index) {
              final Duration option = AttackDurationConstant.options[index];

              return AttackOptionTile(
                label: option.label(l10n),
                selected: _selected == option,
                onTap: () => _pick(context, option),
              );
            },
          ),
          SizedBox(height: SdSpacingConstant.h8),
          // Only offered once there is something to take back — a "clear" on a field that was never set says nothing.
          if (endedAt != null)
            SdButtonV2(
              variant: SdButtonVariantV2.text,
              onPressed: () => Navigator.of(context).pop((endedAt: null)),
              label: l10n.attackDurationNotRecorded,
            ),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension AttackDurationSheetExt on AttackDurationSheet {
  Future<({DateTime? endedAt})?> show(BuildContext context) =>
      showSdBottomSheetV2<({DateTime? endedAt})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
