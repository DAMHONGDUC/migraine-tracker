import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';

/// How much of a free record limit is spent. The look is [SdFreeLimitProgressV2];
/// this holds the two things the design system may not know — the localized
/// strings and the paywall the meter taps through to.
class FreeLimitProgress extends ConsumerWidget {
  const FreeLimitProgress({
    required this.titleBuilder,
    required this.used,
    required this.limit,
    super.key,
  });

  /// The headline, given how many are left. A builder rather than a string so the subtraction lives here and not at each call site.
  final String Function(int left) titleBuilder;

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int left = (limit - used).clamp(0, limit);

    return SdFreeLimitProgressV2(
      title: titleBuilder(left),
      countLabel: context.l10n.freeLimitUsed(used, limit),
      used: used,
      limit: limit,
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}
