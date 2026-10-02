import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/services/attack_window.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/attack_filters.dart';
import '../../domain/services/attack_filterer.dart';
import 'locked_history_sheet.dart';

/// One attack row, shared by the list and calendar views. Taps through to the attack detail screen.
///
/// **A row behind the free window is drawn blurred rather than dropped**
/// (owner's rule, 2026-09-21). It used to be absent, and an absence says
/// nothing: the user could not tell a plan limit from a record that had never
/// been written. Blurred, the row says there is something there, the tag says
/// what it would take to read it, and the tap says why.
///
/// **This widget is the one that decides**, off `freeHistoryStartProvider`
/// rather than off a flag its callers pass. The list and the calendar both
/// draw it, and a lock passed in twice is two places that can disagree about
/// one row. Watching that provider is also the safe way to depend on the
/// entitlement — see its own note on why it is not a stream.
class AttackTile extends ConsumerWidget {
  const AttackTile({required this.attack, super.key});

  final Attack attack;

  /// The blur and the veil over a locked row, taken from [PremiumChartLock] so
  /// the two locked surfaces in the app read as one treatment.
  ///
  /// The row is a fifth the height of a chart card, so the chart's centred
  /// unlock button has nowhere to go here — the tag carries that job instead,
  /// and the veil is only there to stop the blurred text reading as a render
  /// glitch.
  static double get blurSigma => PremiumChartLock.blurSigma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool locked = AttackWindow.locks(
      attack,
      ref.watch(freeHistoryStartProvider),
    );
    final when = DateFormat.yMMMd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: locked
          ? _LockedCard(attack: attack, when: when)
          : _card(context, when),
    );
  }

  Widget _card(BuildContext context, String when) {
    return SdCardV2(
      child: ListTile(
        // The avatar shows a bare number — tell VoiceOver what it means.
        leading: Semantics(
          label: context.l10n.a11yIntensityLabel(
            attack.intensity,
            attack.intensity.severityLabel(context.l10n),
          ),
          excludeSemantics: true,
          child: _IntensityAvatar(intensity: attack.intensity),
        ),
        title: Text(
          attack.regions.label(context.l10n),
          style: AppTextStyle.bodyLarge,
          maxLines: 1,
          // An attack can name every area of the head, and the row is one line: the tile is a way in, the detail screen is the reading.
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          attack.medicationName == null
              ? when
              : '$when · ${attack.medicationName}',
          style: AppTextStyle.bodyMedium.secondary,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_PressureTag.of(attack) case final Widget tag) ...[
              tag,
              SizedBox(width: SdSpacingConstant.w8),
            ],
            SdIconV2(
              icon: AppIconConstant.disclosure,
              size: AppIconSize.small,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () => context.pushNamed(
          AppRoutes.attack.name,
          pathParameters: {AppRoutes.attackIdParam: attack.id},
        ),
      ),
    );
  }
}

/// The same row, unreadable: its own content blurred under a veil, the tag
/// over it, and a tap that explains instead of opening the attack.
///
/// The real row is what gets blurred, not a stand-in — the shape under the
/// blur is this attack's own, so the list keeps its rhythm and a long row
/// stays a long row. `ExcludeSemantics` is what keeps that honest: VoiceOver
/// must not read out the intensity and the medication that the blur is
/// covering, so the row's only accessible name is the tag's.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.attack, required this.when});

  final Attack attack;
  final String when;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      child: Semantics(
        container: true,
        button: true,
        label: context.l10n.historyLockedTag,
        child: InkWell(
          onTap: () => const LockedHistorySheet().show(context),
          child: Stack(
            children: <Widget>[
              // ClipRect: a blur bleeds past its bounds and would fog the card's edge.
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: AttackTile.blurSigma,
                    sigmaY: AttackTile.blurSigma,
                  ),
                  child: ExcludeSemantics(
                    child: IgnorePointer(child: _blurred(context)),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: context.colorScheme.surface.withValues(
                    alpha: PremiumChartLock.scrimOpacity,
                  ),
                  child: Center(
                    child: SdTagV2(label: context.l10n.historyLockedTag),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// This attack's own row, drawn only to be blurred — no tap of its own, and
  /// no disclosure chevron: it leads nowhere while it is locked.
  Widget _blurred(BuildContext context) {
    return ListTile(
      leading: _IntensityAvatar(intensity: attack.intensity),
      title: Text(
        attack.regions.label(context.l10n),
        style: AppTextStyle.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        attack.medicationName == null ? when : '$when · ${attack.medicationName}',
        style: AppTextStyle.bodyMedium.secondary,
      ),
    );
  }
}

/// The intensity in its band's colour — the same four bands the log flow picks from, so a row reads as mild or extreme before the number is.
///
/// Tinted fill and a band-coloured ring rather than a solid disc: the extreme
/// red is below the text contrast floor, so the number stays on a dark fill.
class _IntensityAvatar extends StatelessWidget {
  const _IntensityAvatar({required this.intensity});

  final int intensity;

  static const double _fillAlpha = 0.18;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.intensity(intensity);

    return Container(
      width: SdSpacingConstant.r44,
      height: SdSpacingConstant.r44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: _fillAlpha),
        border: Border.all(color: color, width: SdSpacingConstant.w2),
      ),
      child: Text('$intensity', style: AppTextStyle.titleMedium),
    );
  }
}

/// How far pressure had moved in the 24h before the attack, as a tag — the reading this app exists for, on the row rather than one tap away.
///
/// Falling takes the warning amber; rising and steady stay muted. The arrow
/// carries the direction, so colour is never the only signal (hard rule 3).
/// No reading, no tag: an attack logged offline that was never backfilled has
/// nothing to say here, and a dash would read as a zero.
class _PressureTag {
  const _PressureTag._();

  static const AttackFilterer _filterer = AttackFilterer();

  static Widget? of(Attack attack) {
    final double? delta = attack.weather?.pressureDelta24hHpa;
    if (delta == null) return null;

    final PressureFilter trend = _filterer.pressureTrendOf(attack);
    final String arrow = switch (trend) {
      PressureFilter.falling => '↓',
      PressureFilter.rising => '↑',
      _ => '→',
    };

    return SdTagV2(
      label: '$arrow ${delta.abs().toStringAsFixed(1)}',
      color: trend == PressureFilter.falling
          ? AppColors.warning
          : AppColors.textSecondary,
    );
  }
}
