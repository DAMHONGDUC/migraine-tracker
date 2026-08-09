import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../history/domain/enums/history_view_mode.dart';
import '../../../history/providers.dart';
import '../../../medications/providers.dart';

/// Three shortcuts on one row: History (list), the History chart, and "Add
/// medication" — which opens the Medications tab AND kicks off the add dialog
/// via [medicationAddRequestProvider]. History cards set the view mode before
/// switching branch so they land on the right view.
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

    // Matches all three chips to the tallest — only "Add medication" wraps,
    // and a row of unequal chips reads as a mistake.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _QuickAccessCard(
              icon: Icons.history,
              label: l10n.navHistory,
              onTap: () => openHistory(HistoryViewMode.list),
            ),
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: _QuickAccessCard(
              icon: Icons.bar_chart,
              label: l10n.dashboardChartShortcut,
              onTap: () => openHistory(HistoryViewMode.chart),
            ),
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: _QuickAccessCard(
              icon: Icons.add_circle_outline,
              label: l10n.dashboardAddMedication,
              onTap: addMedication,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SdIconV2(
              icon: icon,
              size: SdSpacingConstant.r20,
              color: context.colorScheme.primary,
            ),
            SizedBox(width: SdSpacingConstant.w6),
            // Two lines, because "Add medication" does not fit beside a glyph
            // in a third of the screen — and Vietnamese runs longer still.
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
