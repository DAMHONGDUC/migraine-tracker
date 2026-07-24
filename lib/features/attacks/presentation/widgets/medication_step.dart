import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/presentation/widgets/medication_name_dialog.dart';
import '../../../medications/providers.dart';

/// Third tap: which medication was taken (or none). Picking only
/// highlights — the app bar's Next confirms, persists the attack and
/// advances to the saved confirmation.
///
/// Everything is one two-column grid. The first row is fixed and holds the
/// two answers that aren't a saved medication — "No medication", then "Add a
/// medication" — so both stay where muscle memory left them however the list
/// changes, and neither can scroll out of reach. The medications follow from
/// the second row, ordered most recently taken first
/// (`medicationsByRecentUseProvider`) so the usual one leads them.
///
/// Fixing that first row also removes the need for separate chrome: with no
/// medications saved the grid is just those two cells, which reads as its
/// own empty state.
class MedicationStep extends ConsumerWidget {
  const MedicationStep({
    required this.hasSelection,
    required this.selectedName,
    required this.onSelected,
    super.key,
  });

  /// Whether *any* pick has been made yet — distinguishes "nothing picked"
  /// from [selectedName] being null because "No medication" was picked.
  final bool hasSelection;
  final String? selectedName;

  /// Called with the medication name, or null for "no medication".
  final ValueChanged<String?> onSelected;

  Future<void> _addMedication(BuildContext context, WidgetRef ref) async {
    final name = await showMedicationNameDialog(context);
    if (name == null || !context.mounted) return;
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
    final medications = ref.watch(medicationsByRecentUseProvider);
    final horizontal = EdgeInsets.symmetric(
      horizontal: AppSpacingConstant.w24,
    );

    return GridView.builder(
      padding: horizontal.copyWith(
        top: AppSpacingConstant.h16,
        bottom: AppSpacingConstant.h16,
      ),
      // Calm and predictable over platform-native bounce: a short list must
      // not rubber-band mid-attack.
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacingConstant.h8,
        crossAxisSpacing: AppSpacingConstant.w8,
        mainAxisExtent: AppSpacingConstant.h64,
      ),
      itemCount: medications.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _Tile.option(
            icon: Icons.block,
            label: l10n.logNoMedication,
            selected: hasSelection && selectedName == null,
            onTap: () => onSelected(null),
          );
        }
        if (i == 1) {
          return _Tile.add(
            label: l10n.logAddMedication,
            onTap: () => _addMedication(context, ref),
          );
        }
        final med = medications[i - 2];
        return _Tile.option(
          icon: Icons.medication_outlined,
          label: med.name,
          selected: hasSelection && selectedName == med.name,
          onTap: () => onSelected(med.name),
        );
      },
    );
  }
}

/// One grid cell. Two semantics, one geometry so the "Add" cell lines up
/// with the medications it trails:
///
/// - [_Tile.option] — a pickable answer (a medication, or "No medication").
///   Shares the location step's tile language so the two steps read as one
///   flow.
/// - [_Tile.add] — the action that opens the add-medication dialog. Never
///   selectable, and teal-tinted like [AppButton.positive] so it reads as
///   additive rather than as one more thing to choose between.
class _Tile extends StatelessWidget {
  const _Tile.option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : _isAdd = false;

  const _Tile.add({required this.label, required this.onTap})
    : icon = Icons.add,
      selected = false,
      _isAdd = true;

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool _isAdd;

  @override
  Widget build(BuildContext context) {
    final Color foreground;
    final Color background;
    final Color borderColor;
    if (_isAdd) {
      foreground = AppColors.secondary;
      background = AppColors.secondary.withValues(alpha: 0.10);
      borderColor = AppColors.secondary.withValues(alpha: 0.45);
    } else if (selected) {
      foreground = AppColors.primary;
      background = AppColors.primary.withValues(alpha: 0.14);
      borderColor = AppColors.primary;
    } else {
      foreground = AppColors.textSecondary;
      background = AppColors.surface;
      borderColor = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Semantics(
      button: true,
      selected: _isAdd ? null : selected,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: AppSpacingConstant.r24),
              SizedBox(width: AppSpacingConstant.w12),
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
