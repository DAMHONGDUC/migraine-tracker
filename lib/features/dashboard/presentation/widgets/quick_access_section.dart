import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';

/// Six shortcuts, three across and two rows down: History, the History chart,
/// Insights, Premium, pressure-drop alerts and Medications.
///
/// **Three per row and nothing scrolls.** Owner's rule from when there were
/// three of them, and it survives the extra row: a third of the screen is the
/// narrowest a tile can be and still show its name, and a horizontally
/// scrolling row advertises a gesture with a cut edge.
///
/// **Every cell is one fixed height, so all six match across both rows.**
/// An `IntrinsicHeight` per row would equalise within a row and let the two
/// rows differ, which reads as two unrelated groups rather than one set —
/// and a `childAspectRatio` would tie height to whatever width is left over,
/// which is how the weather card's details grid came to overflow.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  static const int _columns = 3;

  /// Summed from a cell's contents: the padding, the glyph, the gap, and two
  /// lines of label — two because "Pressure-drop alerts" needs them at a
  /// third of the design width, and every cell is sized for the longest.
  static double get cellHeight =>
      SdSpacingConstant.h12 * 2 +
      SdSpacingConstant.r20 +
      SdSpacingConstant.h6 +
      SdSpacingConstant.h20 * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    final List<_Shortcut> shortcuts = <_Shortcut>[
      _Shortcut(
        icon: Icons.history,
        label: l10n.navHistory,
        onTap: () => openHistory(HistoryViewMode.list),
      ),
      _Shortcut(
        icon: Icons.bar_chart,
        label: l10n.dashboardChartShortcut,
        onTap: () => openHistory(HistoryViewMode.chart),
      ),
      _Shortcut(
        // The nav bar's own Insights glyph — one icon, one destination.
        icon: Icons.insights_outlined,
        label: l10n.navInsights,
        onTap: () => context.goNamed(AppRoutes.insights.name),
      ),
      _Shortcut(
        icon: Icons.workspace_premium_outlined,
        label: l10n.settingsPremium,
        onTap: () => context.pushNamed(AppRoutes.premium.name),
      ),
      _Shortcut(
        icon: Icons.notifications_active_outlined,
        label: l10n.alertsToggleTitle,
        // Through NavigationUtils, like the Settings row: the alert lives on
        // Insights' pressure card now, so "take me to it" is a tab selection
        // plus a branch switch and neither caller should half-remember it.
        onTap: () => NavigationUtils.toPressure(context, ref),
      ),
      _Shortcut(
        icon: Icons.medication_outlined,
        label: l10n.navMedications,
        onTap: () => context.goNamed(AppRoutes.medications.name),
      ),
    ];

    return GridView.builder(
      // A scroll view with a null padding helps itself to the ambient
      // MediaQuery inset — the notch would land inside the section.
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shortcuts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        crossAxisSpacing: SdContentPaddingV2.listItemGap,
        mainAxisSpacing: SdContentPaddingV2.listItemGap,
        mainAxisExtent: cellHeight,
      ),
      itemBuilder: (BuildContext context, int index) =>
          _QuickAccessCard(shortcut: shortcuts[index]),
    );
  }
}

/// One shortcut, ready to draw.
class _Shortcut {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Already localized.
  final String label;
  final VoidCallback onTap;
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.shortcut});

  final _Shortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: shortcut.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SdSpacingConstant.h12,
          horizontal: SdSpacingConstant.w8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Plain text colour, not the accent: a grid of lavender glyphs
            // under the lavender log button was two accents arguing.
            SdIconV2(
              icon: shortcut.icon,
              size: SdSpacingConstant.r20,
              color: AppColors.textPrimary,
            ),
            SizedBox(height: SdSpacingConstant.h6),
            // Two lines rather than an ellipsis: a shortcut whose name is
            // cut off is one the user cannot identify before tapping it.
            Text(
              shortcut.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
