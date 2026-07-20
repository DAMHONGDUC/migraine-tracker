import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/alert_registration_error.dart';
import '../../providers.dart';

/// The alerts block embedded at the top of Settings: enable switch +
/// threshold. Registration errors surface as snackbars here.
class AlertsSection extends ConsumerWidget {
  const AlertsSection({super.key});

  String _errorMessage(AppLocalizations l10n, Object? error) =>
      switch (error) {
        AlertRegistrationException(:final error) => switch (error) {
          AlertRegistrationError.notificationsDenied =>
            l10n.alertsErrorNotifications,
          AlertRegistrationError.locationUnavailable =>
            l10n.alertsErrorLocation,
          AlertRegistrationError.pushUnavailable => l10n.alertsErrorPush,
          AlertRegistrationError.unknown => l10n.alertsErrorGeneric,
        },
        _ => l10n.alertsErrorGeneric,
      };

  Future<void> _pickThreshold(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final picked = await showAppDialog<double>(
      context,
      builder: (dialogContext) =>
          _ThresholdDialog(initial: current, l10n: context.l10n),
    );
    if (picked != null) {
      await ref.read(alertsControllerProvider.notifier).setThreshold(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    ref.listen(alertsControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(l10n, next.error))),
        );
      }
    });

    final settings = switch (ref.watch(alertsControllerProvider)) {
      AsyncData(value: final value) => value,
      AsyncError(:final value) => value,
      _ => null,
    };
    if (settings == null) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: Text(l10n.alertsToggleTitle),
          subtitle: Text(l10n.alertsToggleSubtitle),
          value: settings.enabled,
          onChanged: (value) =>
              ref.read(alertsControllerProvider.notifier).setEnabled(value),
        ),
        ListTile(
          leading: const Icon(Icons.compress),
          title: Text(l10n.alertsThresholdTitle),
          subtitle: Text(
            l10n.onboardingThresholdValue(settings.thresholdHpa.round()),
          ),
          onTap: () => _pickThreshold(context, ref, settings.thresholdHpa),
        ),
      ],
    );
  }
}

class _ThresholdDialog extends StatefulWidget {
  const _ThresholdDialog({required this.initial, required this.l10n});

  final double initial;
  final AppLocalizations l10n;

  @override
  State<_ThresholdDialog> createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<_ThresholdDialog> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.l10n.alertsThresholdTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.l10n.onboardingThresholdValue(_value.round()),
            style: AppTextStyle.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.primary,
            ),
          ),
          Slider(
            value: _value,
            min: 3,
            max: 10,
            divisions: 7,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: widget.l10n.commonCancel,
        ),
        AppButton.primary(
          onPressed: () => Navigator.of(context).pop(_value),
          label: widget.l10n.detailsSave,
        ),
      ],
    );
  }
}
