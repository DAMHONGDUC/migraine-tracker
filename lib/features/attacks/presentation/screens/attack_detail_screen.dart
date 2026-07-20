import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../medications/providers.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';
import '../controllers/attack_detail_controller.dart';
import '../widgets/attack_details_sheet.dart';

/// View and correct a logged attack. Reachable from History; the 3-tap log
/// flow itself stays untouched.
class AttackDetailScreen extends ConsumerWidget {
  const AttackDetailScreen({required this.attackId, super.key});

  final String attackId;

  Future<void> _editIntensity(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final picked = await showAppDialog<int>(
      context,
      builder: (_) => _IntensityDialog(initial: attack.intensity),
    );
    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: picked,
          location: attack.location,
          medicationName: attack.medicationName,
        );
  }

  Future<void> _editLocation(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final picked = await showAppDialog<HeadLocation>(
      context,
      builder: (dialogContext) => AppDialog(
        title: context.l10n.logLocationTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final location in HeadLocation.values)
              AppDialogOption(
                label: location.label(context.l10n),
                selected: location == attack.location,
                onTap: () => Navigator.of(dialogContext).pop(location),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: attack.intensity,
          location: picked,
          medicationName: attack.medicationName,
        );
  }

  Future<void> _editMedication(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final l10n = context.l10n;
    final medications = await ref.read(medicationRepositoryProvider).getAll();
    if (!context.mounted) return;

    // Wrapped so "No medication" (null) is distinguishable from dismissal.
    final picked = await showAppDialog<({String? name})>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.logMedicationTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDialogOption(
              icon: Icons.block,
              label: l10n.logNoMedication,
              selected: attack.medicationName == null,
              onTap: () => Navigator.of(dialogContext).pop((name: null)),
            ),
            for (final med in medications)
              AppDialogOption(
                icon: Icons.medication_outlined,
                label: med.name,
                selected: attack.medicationName == med.name,
                onTap: () => Navigator.of(dialogContext).pop((name: med.name)),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: attack.intensity,
          location: attack.location,
          medicationName: picked.name,
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.attackDetailDeleteTitle,
        content: Text(
          l10n.attackDetailDeleteBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(attackDetailControllerProvider).delete(attackId);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attack = ref.watch(attackByIdProvider(attackId));

    return AppScaffold(
      title: Text(l10n.attackDetailTitle),
      actions: [
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: context.colorScheme.error,
          ),
          onPressed: () => _delete(context, ref),
        ),
        SizedBox(width: AppSpacingConstant.w4),
      ],
      body: switch (attack) {
        AsyncData(value: null) => Center(
          child: Text(l10n.attackDetailDeleted),
        ),
        AsyncData(value: final a?) => ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w16,
            AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
            AppSpacingConstant.w16,
            AppSpacingConstant.w16,
          ),
          children: [
            _Header(attack: a),
            SizedBox(height: AppSpacingConstant.h16),
            _Section(
              children: [
                _EditableRow(
                  label: l10n.attackDetailIntensity,
                  value: '${a.intensity}',
                  swatch: AppColors.intensity(a.intensity),
                  onTap: () => _editIntensity(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailLocation,
                  value: a.location.label(l10n),
                  onTap: () => _editLocation(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailMedication,
                  value: a.medicationName ?? l10n.logNoMedication,
                  onTap: () => _editMedication(context, ref, a),
                ),
              ],
            ),
            SizedBox(height: AppSpacingConstant.h16),
            _WeatherSection(attack: a),
            SizedBox(height: AppSpacingConstant.h16),
            _DetailsSection(attack: a),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.attackDetailDeleted)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.intensity(attack.intensity);
    final when = DateFormat.yMMMMEEEEd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return Row(
      children: [
        Container(
          width: AppSpacingConstant.r64,
          height: AppSpacingConstant.r64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.45),
            border: Border.all(color: color, width: 1.5),
          ),
          child: FittedBox(
            child: Text(
              '${attack.intensity}',
              style: AppTextStyle.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacingConstant.w16),
        Expanded(
          child: Text(when, style: AppTextStyle.titleMedium),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacingConstant.w4,
              bottom: AppSpacingConstant.h8,
            ),
            child: Text(
              title!,
              style: AppTextStyle.titleSmall.secondary,
            ),
          ),
        ],
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  /// Optional colour dot shown *beside* the value — the value itself keeps
  /// the text token (colour never carries meaning through text).
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null) ...[
            Container(
              width: AppSpacingConstant.r12,
              height: AppSpacingConstant.r12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: swatch),
            ),
            SizedBox(width: AppSpacingConstant.w8),
          ],
          Text(value, style: AppTextStyle.bodyLarge),
          SizedBox(width: AppSpacingConstant.w4),
          Icon(
            Icons.chevron_right,
            size: AppSpacingConstant.r20,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: AppTextStyle.bodyLarge),
    );
  }
}

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weather = attack.weather;

    if (weather == null) {
      return _Section(
        title: l10n.attackDetailWeatherTitle,
        children: [
          ListTile(
            leading: Icon(
              Icons.cloud_off,
              color: context.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              l10n.attackDetailNoWeather,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ),
        ],
      );
    }

    final delta = weather.pressureDelta24hHpa;
    return _Section(
      title: l10n.attackDetailWeatherTitle,
      children: [
        _ReadOnlyRow(
          label: l10n.attackDetailPressure,
          value: l10n.attackDetailPressureValue(
            weather.pressureHpa.toStringAsFixed(1),
          ),
        ),
        ListTile(
          title: Text(l10n.attackDetailPressureDelta),
          trailing: Text(
            l10n.attackDetailPressureValue(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
            ),
            style: AppTextStyle.bodyLarge.copyWith(
              // A drop is what this app is about — mark it.
              color: delta <= -5 ? AppColors.error : null,
              fontWeight: delta <= -5 ? FontWeight.w600 : null,
            ),
          ),
        ),
        if (weather.humidityPercent != null)
          _ReadOnlyRow(
            label: l10n.attackDetailHumidity,
            value: l10n.attackDetailHumidityValue(
              weather.humidityPercent!.toStringAsFixed(0),
            ),
          ),
        if (weather.temperatureCelsius != null)
          _ReadOnlyRow(
            label: l10n.attackDetailTemperature,
            value: l10n.attackDetailTemperatureValue(
              weather.temperatureCelsius!.toStringAsFixed(1),
            ),
          ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmpty =
        attack.symptoms.isEmpty &&
        attack.triggers.isEmpty &&
        (attack.notes?.isEmpty ?? true);

    void edit() => showAppBottomSheet<void>(
      context,
      isScrollControlled: true,
      builder: (_) => AttackDetailsSheet(
        attackId: attack.id,
        initialSymptoms: attack.symptoms,
        initialTriggers: attack.triggers,
        initialNotes: attack.notes,
      ),
    );

    return _Section(
      title: l10n.attackDetailDetailsTitle,
      children: [
        if (isEmpty)
          ListTile(
            title: Text(
              l10n.attackDetailNoDetails,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            trailing: const Icon(Icons.add),
            onTap: edit,
          )
        else ...[
          if (attack.symptoms.isNotEmpty)
            _ReadOnlyRow(
              label: l10n.detailsSymptomsLabel,
              value: attack.symptoms.join(', '),
            ),
          if (attack.triggers.isNotEmpty)
            _ReadOnlyRow(
              label: l10n.detailsTriggersLabel,
              value: attack.triggers.join(', '),
            ),
          if (attack.notes?.isNotEmpty ?? false)
            ListTile(
              title: Text(l10n.detailsNotesLabel),
              subtitle: Text(attack.notes!),
            ),
          Padding(
            padding: EdgeInsets.only(
              right: AppSpacingConstant.w8,
              bottom: AppSpacingConstant.h8,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppButton.text(
                onPressed: edit,
                icon: Icons.edit_outlined,
                label: l10n.attackDetailEdit,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Intensity picker: a slider keeps the dialog small (a 10-circle grid
/// belongs to the log flow, not here).
class _IntensityDialog extends StatefulWidget {
  const _IntensityDialog({required this.initial});

  final int initial;

  @override
  State<_IntensityDialog> createState() => _IntensityDialogState();
}

class _IntensityDialogState extends State<_IntensityDialog> {
  late double _value = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = AppColors.intensity(_value.round());
    return AppDialog(
      title: l10n.logIntensityTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_value.round()}',
            style: AppTextStyle.displaySmall.w600,
          ),
          Slider(
            value: _value,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: color,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        AppButton.primary(
          onPressed: () => Navigator.of(context).pop(_value.round()),
          label: l10n.detailsSave,
        ),
      ],
    );
  }
}
