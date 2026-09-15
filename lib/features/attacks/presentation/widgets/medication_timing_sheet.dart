import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/constants/medication_timing_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Records when the dose was taken and when the pain eased, after the fact.
///
/// Two offsets rather than two clocks: nobody remembers that they swallowed
/// something at 09:20, and everybody remembers that it was about half an hour
/// in. The relief offset counts from the DOSE, not from the attack, because
/// "how long did it take to work" is the question the medication is judged on.
class MedicationTimingSheet extends StatefulWidget {
  const MedicationTimingSheet({
    required this.startedAt,
    required this.takenAt,
    required this.reliefAt,
    super.key,
  });

  final DateTime startedAt;
  final DateTime? takenAt;
  final DateTime? reliefAt;

  @override
  State<MedicationTimingSheet> createState() => _MedicationTimingSheetState();
}

class _MedicationTimingSheetState extends State<MedicationTimingSheet> {
  /// Held as offsets while the sheet is open, so a tap on either grid never has to reconstruct the other half's instant.
  Duration? _taken;
  Duration? _relief;

  @override
  void initState() {
    super.initState();
    _taken = widget.takenAt?.difference(widget.startedAt);
    _relief = widget.takenAt == null || widget.reliefAt == null
        ? null
        : widget.reliefAt!.difference(widget.takenAt!);
  }

  void _save() {
    final Duration? taken = _taken;

    Navigator.of(context).pop((
      takenAt: taken == null ? null : widget.startedAt.add(taken),
      // Relief without a dose measures nothing, so it cannot outlive it.
      reliefAt: taken == null || _relief == null
          ? null
          : widget.startedAt.add(taken + _relief!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdSheetContentV2(
      title: l10n.medicationTimingSheetTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.medicationTimingTakenQuestion,
            style: AppTextStyle.titleSmall,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          _OffsetGrid(
            options: MedicationTimingConstant.takenOptions,
            selected: _taken,
            // Zero is the one offset with a word of its own: "0 min in" is not how anyone says "as it started".
            labelOf: (Duration option) => option == Duration.zero
                ? l10n.medicationTimingAtOnset
                : l10n.medicationTimingAfterStart(option.label(l10n)),
            onSelected: (Duration option) => setState(() => _taken = option),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          // The second question only exists once the first is answered: relief is measured from the dose.
          if (_taken != null) ...<Widget>[
            Text(
              l10n.medicationTimingReliefQuestion,
              style: AppTextStyle.titleSmall,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _OffsetGrid(
              options: MedicationTimingConstant.reliefOptions,
              selected: _relief,
              labelOf: (Duration option) => option.label(l10n),
              onSelected: (Duration option) => setState(() => _relief = option),
            ),
            SizedBox(height: SdSpacingConstant.h16),
          ],
          SdButtonV2(
            label: l10n.medicationTimingSave,
            variant: SdButtonVariantV2.primary,
            onPressed: _save,
          ),
          // Only offered once there is something to take back — a "clear" on a field that was never set says nothing.
          if (widget.takenAt != null)
            SdButtonV2(
              label: l10n.medicationTimingNotRecorded,
              variant: SdButtonVariantV2.text,
              onPressed: () =>
                  Navigator.of(context).pop((takenAt: null, reliefAt: null)),
            ),
        ],
      ),
    );
  }
}

class _OffsetGrid extends StatelessWidget {
  const _OffsetGrid({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<Duration> options;
  final Duration? selected;
  final String Function(Duration) labelOf;
  final ValueChanged<Duration> onSelected;

  /// One owner for how tall an option is, as in every other grid in the flow.
  static double get tileHeight => SdSpacingConstant.h56;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      // The sheet owns the scrolling.
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LogFlowConstant.optionsPerRow,
        mainAxisSpacing: SdSpacingConstant.h8,
        crossAxisSpacing: SdSpacingConstant.w8,
        mainAxisExtent: tileHeight,
      ),
      itemCount: options.length,
      itemBuilder: (BuildContext context, int index) => _OffsetTile(
        label: labelOf(options[index]),
        selected: selected == options[index],
        onTap: () => onSelected(options[index]),
      ),
    );
  }
}

class _OffsetTile extends StatelessWidget {
  const _OffsetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.titleSmall.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension MedicationTimingSheetExt on MedicationTimingSheet {
  Future<({DateTime? takenAt, DateTime? reliefAt})?> show(
    BuildContext context,
  ) => showSdBottomSheetV2<({DateTime? takenAt, DateTime? reliefAt})>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
