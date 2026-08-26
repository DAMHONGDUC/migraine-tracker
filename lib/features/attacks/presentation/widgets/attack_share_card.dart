import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/attack.dart';

/// The picture that leaves the phone: what this attack was, in the fewest
/// facts somebody who is not the patient can act on.
///
/// **It carries only logged fields, and never `notes`.** Notes are where
/// people write the most private thing in the app, and a user who shared one
/// six months ago will not remember that they did.
///
/// A picture rather than a paragraph, because it renders inline in every
/// messaging app and the recipient can keep it — which is the actual use for
/// half the people who reach for this: proof, to somebody who does not
/// believe the illness is real.
class AttackShareCard extends StatelessWidget {
  const AttackShareCard({required this.attack, super.key});

  final Attack attack;

  /// The card renders at a fixed logical width so the image is the same
  /// shape from a small phone and a tablet alike.
  static const double width = 340;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final DateTime startedAt = attack.startedAt.toLocal();
    final Duration? duration = attack.duration;

    return Container(
      width: width,
      padding: EdgeInsets.all(SdSpacingConstant.w20),
      color: context.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.attackShareHeadline, style: AppTextStyle.labelSmall.secondary),
          SizedBox(height: SdSpacingConstant.h8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              SdColorDotV2(color: AppColors.intensity(attack.intensity)),
              SizedBox(width: SdSpacingConstant.w8),
              Text(
                '${attack.intensity}/10',
                style: AppTextStyle.displaySmall.w600,
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h12),
          _CardRow(
            label: l10n.attackShareStarted,
            value: DateFormat.yMMMd(
              l10n.localeName,
            ).add_Hm().format(startedAt),
          ),
          if (duration != null)
            _CardRow(
              label: l10n.attackDetailDuration,
              value: duration.label(l10n),
            ),
          if (attack.regions.isNotEmpty)
            _CardRow(
              label: l10n.attackDetailLocation,
              value: attack.regions.label(l10n),
            ),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Both halves flex, so a long localized location cannot squeeze the
          // label into a column of single letters — the same rule the attack
          // detail rows follow.
          Expanded(
            child: Text(label, style: AppTextStyle.bodySmall.secondary),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyle.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
