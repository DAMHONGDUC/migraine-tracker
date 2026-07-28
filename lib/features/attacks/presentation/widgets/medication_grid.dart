import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/presentation/widgets/medication_name_dialog.dart';
import '../../../medications/providers.dart';

/// The medication picker's two-column grid, shared by the log flow's third
/// tap ([MedicationStep]) and the attack detail's edit sheet.
///
/// The first row is fixed and holds the two answers that aren't a saved
/// medication — "No medication", then "Add a medication" — so both stay
/// where muscle memory left them however the list changes. The medications
/// follow, most recently taken first.
///
/// Shrink-wraps and never scrolls itself: whatever holds it owns the
/// scrolling (the log step's viewport, the sheet's scroll view). Adding a
/// medication lives here too, so both callers get the same "adding it also
/// picks it" behaviour.
class MedicationGrid extends ConsumerWidget {
  const MedicationGrid({
    required this.hasSelection,
    required this.selectedName,
    required this.onSelected,
    this.query = '',
    super.key,
  });

  /// Whether *any* pick has been made yet — distinguishes "nothing picked"
  /// from [selectedName] being null because "No medication" was picked.
  final bool hasSelection;
  final String? selectedName;

  /// Called with the medication name, or null for "no medication".
  final ValueChanged<String?> onSelected;

  /// Name filter from the caller's search field. Only the medications are
  /// filtered; the fixed first row always stays put.
  final String query;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
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
        mainAxisSpacing: AppSpacingConstant.h8,
        crossAxisSpacing: AppSpacingConstant.w8,
        mainAxisExtent: AppSpacingConstant.h64,
      ),
      itemCount: medications.length + 2,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return _Tile(
            kind: _TileKind.option,
            icon: Icons.block,
            label: l10n.logNoMedication,
            selected: hasSelection && selectedName == null,
            onTap: () => onSelected(null),
          );
        }
        if (i == 1) {
          return _Tile(
            kind: _TileKind.add,
            icon: Icons.add,
            label: l10n.logAddMedication,
            onTap: () => _add(context, ref),
          );
        }
        final Medication med = medications[i - 2];

        return _Tile(
          kind: _TileKind.option,
          icon: Icons.medication_outlined,
          label: med.name,
          selected: hasSelection && selectedName == med.name,
          onTap: () => onSelected(med.name),
        );
      },
    );
  }
}

/// What a [_Tile] means — the look is a prop, like [AppButtonVariant].
///
/// - [option] — a pickable answer (a medication, or "No medication"). Shares
///   the location step's tile language so the two steps read as one flow.
/// - [add] — the action that opens the add-medication dialog. Never
///   selectable, and teal-tinted like [AppButtonVariant.positive] so it
///   reads as additive rather than as one more thing to choose between.
enum _TileKind { option, add }

/// One grid cell. Two semantics, one geometry so the "Add" cell lines up
/// with the medications it trails.
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
      background = AppColors.surface;
      borderColor = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Semantics(
      button: true,
      selected: isAdd ? null : selected,
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
            children: <Widget>[
              AppIcon(icon, color: foreground, size: AppSpacingConstant.r24),
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
