import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/constants/app_content_padding.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/head_location_label.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_value_slider.dart';
import '../../../../medications/providers.dart';
import '../../../domain/entities/attack.dart';
import '../../../domain/enums/head_location.dart';
import '../../../providers.dart';
import '../../widgets/attack_details_sheet.dart';
import '../../widgets/head_diagram.dart';

part 'attack_detail_screen_details_section.dart';
part 'attack_detail_screen_editable_row.dart';
part 'attack_detail_screen_header.dart';
part 'attack_detail_screen_intensity_dialog.dart';
part 'attack_detail_screen_location_diagram.dart';
part 'attack_detail_screen_read_only_row.dart';
part 'attack_detail_screen_section.dart';
part 'attack_detail_screen_weather_section.dart';

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
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
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
      title: Text(l10n.attackDetailTitle, style: AppTextStyle.titleLarge),
      actions: [
        IconButton(
          icon: AppIcon(Icons.delete_outline, color: context.colorScheme.error),
          onPressed: () => _delete(context, ref),
        ),
        SizedBox(width: AppSpacingConstant.w4),
      ],
      body: switch (attack) {
        AsyncData(value: null) || AsyncError() => Center(
          child: Text(l10n.attackDetailDeleted, style: AppTextStyle.bodyLarge),
        ),
        AsyncData(value: final a?) => ListView(
          padding: AppContentPadding.screen(context),
          children: [
            _Header(attack: a),
            SizedBox(height: AppSpacingConstant.h16),
            _Section(
              children: [
                _LocationDiagram(location: a.location),
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
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
