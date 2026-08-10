import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';
import '../../../premium/providers.dart';

/// Shortcuts on one row: History (list), the History chart, and Weather.
/// History tiles set the view mode before switching branch so they land on the
/// right view; Weather opens `/pressure`.
///
/// **Weather replaced an "Add medication" tile**, whose two-line label was the
/// only thing forcing the row taller than one line of text.
///
/// **Weather is premium-gated**, like every other way into `/pressure`: the
/// screen is the forecast and the alert controls, both premium's, and
/// `PressureCard` on Insights stopped opening for free users. This tile was
/// the one door left unlocked — a wall the user could walk past.
///
/// **All three fit on the screen, and no part of the row scrolls.** Owner's
/// rule. It was a horizontally scrolling row of fixed-width chips, where the
/// third was cut by the screen edge to say "there is more that way" — but
/// there never was more than these three, so the cut edge was advertising a
/// gesture that revealed nothing.
///
/// Each tile takes a third of the row, so they are the same width whatever
/// their labels, and `IntrinsicHeight` makes them the same height as the
/// tallest. The glyph sits above the label rather than beside it: a third of
/// the screen is too narrow to put both on one line, and a shortcut whose name
/// is cut off is one the user cannot identify before tapping it.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bool hasPremium = ref.watch(hasPremiumProvider);

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    // No padding of its own any more: it sat outside the dashboard's gutter
    // to reach the physical screen edge, and nothing needs that now.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SdContentPaddingV2.listItemGap,
        children: <Widget>[
          Expanded(
            child: _QuickAccessCard(
              icon: Icons.history,
              label: l10n.navHistory,
              onTap: () => openHistory(HistoryViewMode.list),
            ),
          ),
          Expanded(
            child: _QuickAccessCard(
              icon: Icons.bar_chart,
              label: l10n.dashboardChartShortcut,
              onTap: () => openHistory(HistoryViewMode.chart),
            ),
          ),
          Expanded(
            child: _QuickAccessCard(
              // Locked, the glyph becomes the lock and the label stays put —
              // the same swap the "Add reminder" button makes. A shortcut has
              // to keep saying what it opens; it never becomes the pitch.
              icon: hasPremium ? Icons.compress : Icons.lock_outline,
              label: l10n.dashboardWeatherShortcut,
              // Straight to the paywall: the lock is the announcement, so
              // there is nothing for a dialog in front of it to add.
              onTap: hasPremium
                  ? () => context.pushNamed(AppRoutes.pressure.name)
                  : () => NavigationUtils.toPaywall(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SdSpacingConstant.h12,
          horizontal: SdSpacingConstant.w8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Plain text colour, not the accent: three lavender glyphs in a
            // row under the lavender log button was two accents arguing.
            SdIconV2(
              icon: icon,
              size: SdSpacingConstant.r20,
              color: AppColors.textPrimary,
            ),
            SizedBox(height: SdSpacingConstant.h6),
            // Two lines rather than an ellipsis: a shortcut whose name is
            // cut off is one the user cannot identify before tapping it.
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppTextStyle.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
