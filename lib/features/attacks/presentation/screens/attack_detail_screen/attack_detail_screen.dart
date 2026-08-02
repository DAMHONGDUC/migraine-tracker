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
import '../../../../../core/widgets/buttons/app_bar_button.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../domain/entities/attack.dart';
import '../../../domain/enums/head_location.dart';
import '../../../providers.dart';
import '../../widgets/attack_details_sheet.dart';
import '../../widgets/head_diagram.dart';
import '../../widgets/intensity_sheet.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/medication_picker_sheet.dart';

part 'attack_detail_screen_details_section.dart';
part 'attack_detail_screen_editable_row.dart';
part 'attack_detail_screen_header.dart';
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
    final int? picked = await IntensitySheet(
      initial: attack.intensity,
    ).show(context);

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
    final HeadLocation? picked = await LocationPickerSheet(
      selected: attack.location,
    ).show(context);

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
    // Wrapped so "No medication" (null) is distinguishable from dismissal.
    final ({String? name})? picked = await MedicationPickerSheet(
      selectedName: attack.medicationName,
    ).show(context);

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
        AppBarButton(
          icon: Icons.delete_outline,
          color: context.colorScheme.error,
          tooltip: l10n.attackDetailDeleteTitle,
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
            _LocationDiagram(location: a.location),
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
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
