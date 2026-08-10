import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/medication_effect_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/medication_effect.dart';

/// Records whether the medication taken for an attack helped.
///
/// Asked after the fact and never in the log flow (hard rule 5): at the
/// moment an attack is logged the drug has not had time to work, so the
/// question could only be answered wrong.
///
/// Pops `(effect: …)`; `(effect: null)` takes the answer back, and a bare
/// null is dismissal — the X must never clear what the user already said.
class MedicationEffectSheet extends StatelessWidget {
  const MedicationEffectSheet({required this.selected, super.key});

  final MedicationEffect? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SdSheetContentV2(
      title: l10n.medicationEffectSheetTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // The sheet owns the scrolling.
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LogFlowConstant.optionsPerRow,
              mainAxisSpacing: SdSpacingConstant.h8,
              crossAxisSpacing: SdSpacingConstant.w8,
              mainAxisExtent: SdSpacingConstant.h64,
            ),
            itemCount: MedicationEffect.values.length,
            itemBuilder: (BuildContext context, int index) {
              final MedicationEffect effect = MedicationEffect.values[index];

              return _EffectTile(
                effect: effect,
                selected: selected == effect,
                onTap: () =>
                    Navigator.of(context).pop((effect: effect)),
              );
            },
          ),
          SizedBox(height: SdSpacingConstant.h8),
          // Only once there is something to take back — a "clear" on a field
          // that was never set says nothing.
          if (selected != null)
            SdButtonV2(
              variant: SdButtonVariantV2.text,
              onPressed: () =>
                  Navigator.of(context).pop((effect: null)),
              label: l10n.medicationEffectNotRecorded,
            ),
        ],
      ),
    );
  }
}

class _EffectTile extends StatelessWidget {
  const _EffectTile({
    required this.effect,
    required this.selected,
    required this.onTap,
  });

  final MedicationEffect effect;
  final bool selected;
  final VoidCallback onTap;

  /// Three distinct glyphs, because colour is never the only signal
  /// (hard rule: accessibility, and the palette carries no green/red pair
  /// that clears the contrast floor for text).
  static const Map<MedicationEffect, IconData> _icons =
      <MedicationEffect, IconData>{
        MedicationEffect.helped: Icons.sentiment_very_satisfied,
        MedicationEffect.partly: Icons.sentiment_neutral,
        MedicationEffect.didNotHelp: Icons.sentiment_dissatisfied,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: effect.label(l10n),
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
            children: <Widget>[
              SdIconV2(
                icon: _icons[effect]!,
                color: color,
                size: SdSpacingConstant.r24,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  effect.label(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.titleSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension MedicationEffectSheetExt on MedicationEffectSheet {
  Future<({MedicationEffect? effect})?> show(BuildContext context) =>
      showSdBottomSheetV2<({MedicationEffect? effect})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
