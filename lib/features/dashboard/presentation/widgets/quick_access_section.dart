import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';
import '../../../medications/providers.dart';

/// Shortcuts on one horizontally scrolling row: History (list), the History
/// chart, and "Add medication" — which opens the Medications tab AND kicks off
/// the add dialog via [medicationAddRequestProvider]. History cards set the
/// view mode before switching branch so they land on the right view.
///
/// **The row is full-bleed and this is what tells the user it scrolls.** It
/// carries the screen gutter as its own scroll padding, so the first chip
/// still lines up with everything above it — but an overflowing chip runs to
/// the physical edge of the screen and is cut by it, which reads as "there is
/// more that way" the way a chip stopping short of a margin never does. No
/// fade, no arrows, no dots: on a near-black background an edge fade is
/// invisible, and the other two are chrome announcing a gesture the cut edge
/// already announces.
///
/// It degrades on its own. `AppScrollBehavior` refuses to scroll content that
/// fits, so on a wide screen the chips simply sit there — no bounce, and no
/// affordance promising something that is not there.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    void openHistory(HistoryViewMode mode) {
      ref.read(historyViewModeProvider.notifier).select(mode);
      context.goNamed(AppRoutes.history.name);
    }

    void addMedication() {
      ref.read(medicationAddRequestProvider.notifier).request();
      context.goNamed(AppRoutes.medications.name);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      // Stretch is what makes every chip as tall as the tallest — without it
      // the two one-line chips come out shorter than the wrapping one.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SdContentPaddingV2.listItemGap,
          children: [
            _QuickAccessCard(
              icon: Icons.history,
              label: l10n.navHistory,
              onTap: () => openHistory(HistoryViewMode.list),
            ),
            _QuickAccessCard(
              icon: Icons.bar_chart,
              label: l10n.dashboardChartShortcut,
              onTap: () => openHistory(HistoryViewMode.chart),
            ),
            _QuickAccessCard(
              icon: Icons.add_circle_outline,
              label: l10n.dashboardAddMedication,
              onTap: addMedication,
            ),
          ],
        ),
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

  /// Every chip is this wide, whatever its label — the row is a set of three
  /// of the same thing, not three differently sized objects. Wide enough that
  /// the longest label in either locale ("Add medication", "Thêm thuốc") fits
  /// in two lines beside the glyph without ellipsing.
  static double get width => SdSpacingConstant.w160;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SdCardV2(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: SdSpacingConstant.h12,
            horizontal: SdSpacingConstant.w16,
          ),
          child: Row(
            children: [
              // Plain text colour, not the accent: three lavender glyphs in a
              // row under the lavender log button was two accents arguing.
              SdIconV2(
                icon: icon,
                size: SdSpacingConstant.r20,
                color: AppColors.textPrimary,
              ),
              SizedBox(width: SdSpacingConstant.w6),
              // Two lines rather than an ellipsis: a shortcut whose name is
              // cut off is one the user cannot identify before tapping it.
              Expanded(
                child: Text(label, maxLines: 2, style: AppTextStyle.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
