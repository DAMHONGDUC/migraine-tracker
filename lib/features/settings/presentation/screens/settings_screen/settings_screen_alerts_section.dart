part of 'settings_screen.dart';

/// Premium-gated as a whole: a free user gets the locked tile, never the
/// switch — the gate never builds [AlertsSection] at all.
class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    return PremiumTileGate(
      icon: Icons.notifications_active_outlined,
      title: context.l10n.alertsToggleTitle,
      child: const AlertsSection(),
    );
  }
}
