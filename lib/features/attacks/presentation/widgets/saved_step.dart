import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/home_widget_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/attack.dart';
import '../../domain/services/falling_pressure_month_counter.dart';
import '../../providers.dart';
import 'attack_details_sheet.dart';

/// Confirmation after the attack is saved. Calm, static — no flashing.
///
/// **It reads back what was just written** (2026-09-30 redesign): intensity,
/// where, when, and the pressure when a reading is already attached. "Logged."
/// on its own asked the user to trust a save they could not see, at the one
/// moment in the flow they are most likely to have mistapped. The weather row
/// is left out rather than shown pending: attack logging is offline-first and
/// the reading is backfilled later (hard rule 4).
class SavedStep extends ConsumerWidget {
  const SavedStep({
    required this.attackId,
    required this.startedAt,
    required this.onDone,
    super.key,
  });

  final String attackId;

  /// The instant just saved, so the details sheet knows which day a trigger belongs to.
  final DateTime startedAt;
  final VoidCallback onDone;

  /// The tint in the tick's disc and the glow around it — a halo, not a light.
  static const double _discAlpha = 0.14;

  static const FallingPressureMonthCounter _counter =
      FallingPressureMonthCounter();
  static const double _glowAlpha = 0.22;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final Attack? attack = ref.watch(attackByIdProvider(attackId)).value;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV2.horizontal,
        vertical: SdSpacingConstant.h24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          width: SdSpacingConstant.r88,
                          height: SdSpacingConstant.r88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(
                              alpha: _discAlpha,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: _glowAlpha,
                                ),
                                blurRadius: SdSpacingConstant.r64,
                              ),
                            ],
                          ),
                          child: SdIconV2(
                            icon: AppIconConstant.saved,
                            size: AppIconSize.xLarge,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: SdSpacingConstant.h20),
                    Text(
                      l10n.logSavedTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.headlineMedium,
                    ),
                    SizedBox(height: SdSpacingConstant.h4),
                    Text(
                      l10n.logSavedSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.bodyLarge.secondary,
                    ),
                    if (attack != null) ...[
                      SizedBox(height: SdSpacingConstant.h32),
                      _SavedSummary(attack: attack),
                      if (_counter.count(
                            attack,
                            ref.watch(attacksStreamProvider).value ??
                                const <Attack>[],
                          )
                          case final int count) ...[
                        SizedBox(height: SdSpacingConstant.h12),
                        _PressurePatternNote(count: count),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            onPressed: () => AttackDetailsSheet(
              attackId: attackId,
              startedAt: startedAt,
            ).show(context),
            label: l10n.logAddDetails,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            onPressed: onDone,
            label: l10n.logDone,
          ),
        ],
      ),
    );
  }
}

/// The saved attack, one labelled row per answer, dividers between.
class _SavedSummary extends StatelessWidget {
  const _SavedSummary({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double? pressure = attack.weather?.pressureHpa;
    final double? delta = attack.weather?.pressureDelta24hHpa;

    final List<Widget> rows = [
      _SummaryRow(
        label: l10n.attackDetailIntensity,
        value: SdTagV2(
          label:
              '${attack.intensity} · ${attack.intensity.severityTitle(l10n)}',
          color: AppColors.intensity(attack.intensity),
        ),
      ),
      _SummaryRow(
        label: l10n.attackDetailLocation,
        value: _value(attack.regions.label(l10n)),
      ),
      _SummaryRow(
        label: l10n.attackDetailStartedAt,
        value: _value(
          DateFormat.MMMd(
            l10n.localeName,
          ).add_jm().format(attack.startedAt.toLocal()),
        ),
      ),
      if (pressure != null && delta != null)
        _SummaryRow(
          label: l10n.weatherDetailPressure,
          value: _value(
            '${l10n.weatherPressureValue(pressure.toStringAsFixed(1))} '
            '${_arrow(delta)} ${delta.abs().toStringAsFixed(1)}',
          ),
        ),
    ];

    return SdCardV2(
      child: Column(
        children: [
          for (final (int index, Widget row) in rows.indexed) ...[
            if (index > 0) const SdDividerV2(),
            row,
          ],
        ],
      ),
    );
  }

  /// The same steady band History's row tag draws, so one attack never reads "↑ 0.3" here and "→ 0.3" there.
  static String _arrow(double delta) {
    if (delta <= -HomeWidgetConstant.trendThresholdHpa) return '↓';
    if (delta >= HomeWidgetConstant.trendThresholdHpa) return '↑';
    return '→';
  }

  Widget _value(String text) => Text(
    text,
    textAlign: TextAlign.end,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyle.bodyMedium,
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV2.horizontal,
        vertical: SdSpacingConstant.h12,
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyle.bodyMedium.secondary),
          SizedBox(width: SdSpacingConstant.w16),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

/// The one personal line after a log: how many of this month's attacks came on a falling-pressure day.
///
/// The peak of the flow is the save, and the app's whole promise is the
/// pressure link — so when this attack is part of that pattern, the end of the
/// flow says so once, in the accent's tint, with nothing to tap.
class _PressurePatternNote extends StatelessWidget {
  const _PressurePatternNote({required this.count});

  final int count;

  static const double _fillAlpha = 0.08;
  static const double _borderAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      fillColor: AppColors.primary.withValues(alpha: _fillAlpha),
      borderColor: AppColors.primary.withValues(alpha: _borderAlpha),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV2.horizontal,
          vertical: SdSpacingConstant.h12,
        ),
        child: Row(
          children: [
            SdIconV2(
              icon: AppIconConstant.pressure,
              size: AppIconSize.medium,
              color: AppColors.primary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                context.l10n.logSavedPressurePattern(count),
                style: AppTextStyle.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
