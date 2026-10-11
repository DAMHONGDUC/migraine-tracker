import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/enums/attack_filters.dart';
import '../../domain/services/attack_filterer.dart';

/// One attack row, shared by the list and calendar views. Taps through to the attack detail screen.
class AttackTile extends StatelessWidget {
  const AttackTile({required this.attack, super.key});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
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
      child: _card(context, when),
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
