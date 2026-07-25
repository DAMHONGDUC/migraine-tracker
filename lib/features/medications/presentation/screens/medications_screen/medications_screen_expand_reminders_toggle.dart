part of 'medications_screen.dart';

/// "Show N more" / "Show less" row under a card's reminder list once it's
/// past [_MedicationCard.collapsedLimit].
class _ExpandRemindersToggle extends StatelessWidget {
  const _ExpandRemindersToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      dense: true,
      leading: AppIcon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: AppColors.primary,
      ),
      title: Text(
        expanded
            ? l10n.medicationsShowFewerReminders
            : l10n.medicationsShowMoreReminders(hiddenCount),
        style: AppTextStyle.labelLarge.copyWith(color: AppColors.primary),
      ),
      onTap: onTap,
    );
  }
}
