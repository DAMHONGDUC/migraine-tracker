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

/// Three shortcuts on one row: History, Medications, pressure-drop alerts.
///
/// **Three per row and nothing scrolls.** Owner's original rule, and it is
/// back to one row: a third of the screen is the narrowest a tile can be and
/// still show its name, and a horizontally scrolling row advertises a gesture
/// with a cut edge.
///
/// **It was six, over two rows** — the History chart, Insights and Premium
/// have gone (owner's call). Each of the three that left is a place the app
/// already puts in front of the user: Insights and History have their own nav
/// bar tabs, and Premium leads Settings. What is left is the three that have
/// nowhere else to be reached from in one tap.
///
/// **Every cell is one fixed height.** A `childAspectRatio` would tie height
/// to whatever width is left over, which is how the old weather card's
/// details grid came to overflow; the extent is stated instead.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  static const int _columns = 3;

  /// Summed from a cell's contents: the padding, the glyph, the gap and ONE
  /// line of label.
  ///
  /// One line since the alert tile stopped spelling out "Pressure-drop
  /// alerts" — that label was the only thing that needed two, and every cell
  /// is sized for the longest. "Medications" is the widest of the three left
  /// and fits a third of the design width on its own line.
  static double get cellHeight =>
      SdSpacingConstant.h12 * 2 +
      SdSpacingConstant.r20 +
      SdSpacingConstant.h6 +
      SdSpacingConstant.h20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // The list, always: the chart tile beside this one is gone, so there is
    // no mode to choose between any more — and History remembers the last
    // mode, which would otherwise land a shortcut named "History" on a chart.
    void openHistory() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.list);
      context.goNamed(AppRoutes.history.name);
    }

    final List<_Shortcut> shortcuts = <_Shortcut>[
      _Shortcut(
        icon: Icons.history,
        label: l10n.navHistory,
        onTap: openHistory,
      ),
      _Shortcut(
        icon: Icons.medication_outlined,
        label: l10n.navMedications,
        onTap: () => context.goNamed(AppRoutes.medications.name),
      ),
      _Shortcut(
        icon: Icons.notifications_active_outlined,
        label: l10n.dashboardAlertShortcut,
        // Through NavigationUtils, like the Settings row: the alert lives on
        // Insights' pressure card now, so "take me to it" is a tab selection
        // plus a branch switch and neither caller should half-remember it.
        onTap: () =>
            NavigationUtils.toPressure(context, ref, highlightAlert: true),
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
            // One line now that every label fits one. A longer locale string
            // would ellipse rather than overflow the fixed cell — check a new
            // label against the third-width before adding it.
            Text(
              shortcut.label,
              maxLines: 1,
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
