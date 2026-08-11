import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import '../theme/app_text_style.dart';

/// How much of a free record limit is spent: the sentence a user reads first,
/// then the bar behind it.
///
/// One widget for every limited record, so the surfaces that show one cannot
/// word it or measure it differently. It never decides whether to appear —
/// the caller's `*UsedProvider` returns null while premium, and premium has
/// no limit to draw.
///
/// Tapping opens the paywall directly, with no [RecordLimitDialog] in front:
/// naming the limit before the pitch is that dialog's whole job, and this
/// surface has already done it.
class FreeLimitProgress extends ConsumerWidget {
  const FreeLimitProgress({
    required this.icon,
    required this.titleBuilder,
    required this.used,
    required this.limit,
    super.key,
  });

  final IconData icon;

  /// The headline, given how many are left. A builder rather than a string so
  /// the subtraction lives here and not at each call site.
  final String Function(int left) titleBuilder;

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int left = (limit - used).clamp(0, limit);
    final double progress = limit <= 0 ? 1 : (used / limit).clamp(0, 1);

    return SdCardV2(
      onTap: () => NavigationUtils.toPaywall(context, ref),
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SdIconV2(
                  icon: icon,
                  size: SdSpacingConstant.r20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: Text(
                    titleBuilder(left),
                    style: AppTextStyle.bodyMedium,
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                SdIconV2(
                  icon: Icons.chevron_right,
                  size: SdSpacingConstant.r20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h12),
            LinearProgressIndicator(
              value: progress,
              minHeight: SdSpacingConstant.h6,
              borderRadius: BorderRadius.circular(SdSpacingConstant.r3),
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              context.l10n.freeLimitUsed(used, limit),
              style: AppTextStyle.bodySmall.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
