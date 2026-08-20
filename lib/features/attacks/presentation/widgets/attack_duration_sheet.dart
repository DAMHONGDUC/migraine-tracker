import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/attack_duration_constant.dart';
import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// Records how long an attack lasted, after the fact.
///
/// Never part of the log flow: at the moment an attack is logged nobody knows
/// how long it will run, and the three taps are sacred (hard rule 5).
///
/// Asks for a duration, not an end time — "about four hours" is what a person
/// remembers, "it stopped at 14:37" is not. The end time is then derived from
/// the attack's start.
///
/// Pops `(endedAt: …)`; `(endedAt: null)` is the user taking the answer back,
/// and a bare null is dismissal. The two must stay distinguishable or the X
/// would silently clear a duration.
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
          // The common case for an attack still running: the user is looking
          // at the app because it has just stopped.
          if (!sinceStart.isNegative)
            SizedBox(
              // The same box the grid gives every other option. Left to size
              // itself this one shrank to its line of text and sat above the
              // grid as a thin pill among ten chunky tiles - it is the same
              // kind of answer, so it is the same kind of target.
              height: _DurationTile.height,
              child: _DurationTile(
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
              mainAxisExtent: _DurationTile.height,
            ),
            itemCount: AttackDurationConstant.options.length,
            itemBuilder: (BuildContext context, int index) {
              final Duration option = AttackDurationConstant.options[index];

              return _DurationTile(
                label: option.label(l10n),
                selected: _selected == option,
                onTap: () => _pick(context, option),
              );
            },
          ),
          SizedBox(height: SdSpacingConstant.h8),
          // Only offered once there is something to take back — a "clear"
          // on a field that was never set says nothing.
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

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  /// One owner for how tall an option is, used by the grid's
  /// `mainAxisExtent` and by the full-width tile above it — the two used to
  /// carry the number separately and only one of them had it.
  static double get height => SdSpacingConstant.h64;

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: detail == null ? label : '$label, $detail',
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                // A step above the sheet, or the tile disappears into it.
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.titleSmall.copyWith(color: color),
                ),
              ),
              if (detail != null) ...<Widget>[
                SizedBox(width: SdSpacingConstant.w8),
                Text(detail!, style: AppTextStyle.bodyMedium.secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension AttackDurationSheetExt on AttackDurationSheet {
  Future<({DateTime? endedAt})?> show(BuildContext context) =>
      showSdBottomSheetV2<({DateTime? endedAt})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
