import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import '../theme/app_text_style.dart';

/// How much of a free record limit is spent: one line that says it, and a
/// hairline bar that shows it.
///
/// One widget for every capped record, so the surfaces showing a limit cannot
/// word it or measure it differently. It never decides whether to appear —
/// the caller's `*UsedProvider` returns null while premium, and premium has
/// no limit to draw.
///
/// **Deliberately two rows, not four.** It sits above a list the user came to
/// read, so it states the fact and gets out of the way: the sentence and the
/// counts share one line, the bar is the full width under it, and there is no
/// icon and no chevron competing with either. A block tall enough to be a
/// card here would push the first real item off the screen.
///
/// Tapping opens the paywall directly, with no [RecordLimitDialog] in front:
/// naming the limit before the pitch is that dialog's whole job, and this
/// surface has already done it.
class FreeLimitProgress extends ConsumerWidget {
  const FreeLimitProgress({
    required this.titleBuilder,
    required this.used,
    required this.limit,
    super.key,
  });

  /// The headline, given how many are left. A builder rather than a string so
  /// the subtraction lives here and not at each call site.
  final String Function(int left) titleBuilder;

  final int used;
  final int limit;

  /// Thin on purpose: this is a readout, not the progress of something the
  /// user is waiting on.
  static double get barHeight => SdSpacingConstant.h4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int left = (limit - used).clamp(0, limit);
    final double progress = limit <= 0 ? 1 : (used / limit).clamp(0, 1);
    // Spent, so the bar stops reading as neutral progress and starts reading
    // as a wall. The only colour change in the widget.
    final Color tint = left == 0
        ? context.colorScheme.error
        : context.colorScheme.primary;

    return SdPressableScaleV2(
      pressedScale: 0.99,
      onTap: () => NavigationUtils.toPaywall(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    titleBuilder(left),
                    style: AppTextStyle.bodySmall.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                // The counts, not a percentage: "38/40" says how many are
                // left at a glance, where "95%" has to be worked out.
                Text(
                  context.l10n.freeLimitUsed(used, limit),
                  style: AppTextStyle.bodySmall.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h6),
            ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: barHeight,
                backgroundColor: context.sdTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(tint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
