import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';

/// Three shortcuts on one row: History, Medications, pressure-drop alerts.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  static const int _columns = 3;

  /// Summed from a cell's contents: the padding, the glyph, the gap and ONE line of label.
  static double get cellHeight =>
      SdSpacingConstant.h12 * 2 +
      AppIconSize.large +
      SdSpacingConstant.h6 +
      SdSpacingConstant.h20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // The list, always: the chart tile beside this one is gone, so there is no mode to choose between any more — and History remembers the last mode.
    void openHistory() {
      ref.read(historyViewModeProvider.notifier).select(HistoryViewMode.list);
      context.goNamed(AppRoutes.history.name);
    }

    final List<_Shortcut> shortcuts = <_Shortcut>[
      _Shortcut(
        icon: AppIconConstant.history,
        label: l10n.navHistory,
        onTap: openHistory,
      ),
      _Shortcut(
        icon: AppIconConstant.medication,
        label: l10n.navMedications,
        onTap: () => context.goNamed(AppRoutes.medications.name),
      ),
      _Shortcut(
        icon: AppIconConstant.reminderActive,
        label: l10n.dashboardAlertShortcut,
        // Through NavigationUtils, like the Settings row.
        onTap: () =>
            NavigationUtils.toPressure(context, ref, highlightAlert: true),
      ),
    ];

    return GridView.builder(
      // A scroll view with a null padding helps itself to the ambient MediaQuery inset — the notch would land inside the section.
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
            // Plain text colour, not the accent: a grid of lavender glyphs under the lavender log button was two accents arguing.
            SdIconV2(
              icon: shortcut.icon,
              size: AppIconSize.small,
              color: AppColors.textPrimary,
            ),
            SizedBox(height: SdSpacingConstant.h6),
            // One line now that every label fits one.
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
