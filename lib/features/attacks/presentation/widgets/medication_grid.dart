import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/premium_limit_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/medication_name_dialog.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/providers.dart';

/// The medication picker's two-column grid, shared by the log flow's third tap ([MedicationStep]) and the attack detail's edit sheet.
class MedicationGrid extends ConsumerWidget {
  const MedicationGrid({
    required this.hasSelection,
    required this.selectedName,
    required this.onSelected,
    this.query = '',
    super.key,
  });

  /// Whether *any* pick has been made yet — distinguishes "nothing picked" from [selectedName] being null because "No medication" was picked.
  final bool hasSelection;
  final String? selectedName;

  /// Called with the medication name, or null for "no medication".
  final ValueChanged<String?> onSelected;

  /// Name filter from the caller's search field. Only the medications are filtered; the fixed first row always stays put.
  final String query;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    // The one gate inside the sacred flow, by the owner's call.
    if (!ref.read(canAddMedicationProvider)) {
      await NavigationUtils.toPaywallFromLimit(
        context,
        ref,
        title: context.l10n.medicationLimitTitle(
          PremiumLimitConstant.medications,
        ),
        body: context.l10n.medicationLimitBody(
          PremiumLimitConstant.medications,
        ),
      );
      return;
    }

    final String? name = await const MedicationNameDialog().show(context);

    if (name == null) return;
    await ref
        .read(medicationRepositoryProvider)
        .upsert(
          Medication(
            id: const Uuid().v4(),
            name: name,
            createdAt: DateTime.now().toUtc(),
          ),
        );
    // Mid-attack every tap counts: adding a medication also picks it.
    onSelected(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<Medication> all = ref.watch(medicationsByRecentUseProvider);
    final String needle = query.trim().toLowerCase();
    final List<Medication> medications = needle.isEmpty
        ? all
        : all
              .where(
                (Medication med) => med.name.toLowerCase().contains(needle),
              )
              .toList();

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: SdSpacingConstant.h8,
        crossAxisSpacing: SdSpacingConstant.w8,
        mainAxisExtent: SdSpacingConstant.h64,
      ),
      itemCount: medications.length + 2,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return _Tile(
            kind: _TileKind.option,
            icon: AppIconConstant.noMedication,
            label: l10n.logNoMedication,
            selected: hasSelection && selectedName == null,
            onTap: () => onSelected(null),
          );
        }
        if (i == 1) {
          return _Tile(
            kind: _TileKind.add,
            icon: AppIconConstant.add,
            label: l10n.logAddMedication,
            onTap: () => _add(context, ref),
          );
        }
        final Medication med = medications[i - 2];

        return _Tile(
          kind: _TileKind.option,
          icon: AppIconConstant.medication,
          label: med.name,
          selected: hasSelection && selectedName == med.name,
          onTap: () => onSelected(med.name),
        );
      },
    );
  }
}

/// What a [_Tile] means — the look is a prop, like [SdButtonVariantV2].
enum _TileKind { option, add }

/// One grid cell. Two semantics, one geometry so the "Add" cell lines up with the medications it trails.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.kind,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final _TileKind kind;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Ignored by [_TileKind.add], which is an action and never a choice.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bool isAdd = kind == _TileKind.add;
    final Color foreground;
    final Color background;
    final Color borderColor;

    if (isAdd) {
      foreground = AppColors.secondary;
      background = AppColors.secondary.withValues(alpha: 0.10);
      borderColor = AppColors.secondary.withValues(alpha: 0.45);
    } else if (selected) {
      foreground = AppColors.primary;
      background = AppColors.primary.withValues(alpha: 0.14);
      borderColor = AppColors.primary;
    } else {
      foreground = AppColors.textSecondary;
      // One step above card colour, or it vanishes into the sheet below.
      background = AppColors.surfaceElevated;
      borderColor = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Semantics(
      button: true,
      selected: isAdd ? null : selected,
      label: label,
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: <Widget>[
              SdIconV2(
                icon: icon,
                color: foreground,
                size: AppIconSize.medium,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.titleSmall.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
