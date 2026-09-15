import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/attack_start_constant.dart';
import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import 'attack_option_tile.dart';

/// Corrects when an attack started — the 3am one logged at 9am, or yesterday's logged today.
///
/// Presets rather than a date picker, for the same reason
/// [AttackDurationSheet] uses them: the answer is a small number of hours, and
/// a wheel picker mid-migraine is a control nobody finishes.
class AttackStartSheet extends StatelessWidget {
  const AttackStartSheet({required this.startedAt, this.endedAt, super.key});

  final DateTime startedAt;

  /// When the attack ended, when that is known: a start after it is not an answer, so those presets are refused.
  final DateTime? endedAt;

  void _pick(BuildContext context, DateTime instant) =>
      Navigator.of(context).pop((startedAt: instant));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final DateTime now = DateTime.now().toUtc();

    bool allows(DateTime candidate) {
      final DateTime? end = endedAt;

      return end == null || candidate.isBefore(end);
    }

    return SdSheetContentV2(
      title: l10n.attackStartSheetTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The common case for an attack being logged as it happens.
          SizedBox(
            height: AttackOptionTile.height,
            child: AttackOptionTile(
              label: l10n.attackStartNow,
              selected: now.difference(startedAt).inMinutes.abs() < 1,
              enabled: allows(now),
              onTap: () => _pick(context, now),
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
            itemCount: AttackStartConstant.agoOptions.length,
            itemBuilder: (BuildContext context, int index) {
              final Duration ago = AttackStartConstant.agoOptions[index];
              final DateTime candidate = now.subtract(ago);

              return AttackOptionTile(
                label: l10n.attackStartAgo(ago.label(l10n)),
                // Within a minute of the stored instant is the answer already on file.
                selected: candidate.difference(startedAt).inMinutes.abs() < 1,
                enabled: allows(candidate),
                onTap: () => _pick(context, candidate),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension AttackStartSheetExt on AttackStartSheet {
  Future<({DateTime startedAt})?> show(BuildContext context) =>
      showSdBottomSheetV2<({DateTime startedAt})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
