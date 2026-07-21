import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/providers.dart';

/// Third tap: which medication was taken (or none). Picking only
/// highlights — the app bar's Next confirms, persists the attack and
/// advances to the saved confirmation.
///
/// "No medication", "Add a medication" and every saved medication share one
/// continuous scroll. The two actions start as full-size stacked buttons in
/// the list's own flow; once scrolling would carry them off-screen they
/// collapse into a single compact row pinned to the top, so they stay
/// reachable no matter how long the medication list runs.
class MedicationStep extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<MedicationStep> createState() => _MedicationStepState();
}

class _MedicationStepState extends ConsumerState<MedicationStep> {
  Future<void> _addMedication(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showAppDialog<String>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.logAddMedication,
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.logMedicationNameHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(),
            label: l10n.commonCancel,
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            label: l10n.commonAdd,
          ),
        ],
      ),
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await ref
        .read(medicationRepositoryProvider)
        .upsert(Medication(id: const Uuid().v4(), name: trimmed));
    // Mid-attack every tap counts: adding a medication also picks it.
    widget.onSelected(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final medications =
        ref.watch(medicationsStreamProvider).value ?? const <Medication>[];

    final actions = [
      _Action(
        icon: Icons.close,
        label: l10n.logNoMedication,
        variant: _TileVariant.destructive,
        selected: widget.hasSelection && widget.selectedName == null,
        onTap: () => widget.onSelected(null),
      ),
      _Action(
        icon: Icons.add,
        label: l10n.logAddMedication,
        variant: _TileVariant.positive,
        selected: false,
        onTap: () => _addMedication(context, ref),
      ),
    ];

    final header = _ActionsHeader(actions);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Total laid-out height with the header fully expanded. Each list
        // item is its top gap + a full tile; the list adds bottom padding.
        final listHeight =
            medications.length *
                (AppSpacingConstant.h12 + AppSpacingConstant.h64) +
            AppSpacingConstant.w24;
        final contentHeight = header.maxExtent + listHeight;
        // Nothing to reveal by scrolling → lock it, so a short list can't
        // rubber-band or drag the pinned actions around.
        final fits = contentHeight <= constraints.maxHeight;

        return CustomScrollView(
          physics: fits ? const NeverScrollableScrollPhysics() : null,
          slivers: [
            // The two actions flow with the list, but shrink to a compact
            // (still full-width) pinned block once scrolled past.
            SliverPersistentHeader(pinned: true, delegate: header),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacingConstant.w24,
                0,
                AppSpacingConstant.w24,
                AppSpacingConstant.w24,
              ),
              sliver: SliverList.builder(
                itemCount: medications.length,
                itemBuilder: (context, i) {
                  final med = medications[i];
                  return Padding(
                    padding: EdgeInsets.only(top: AppSpacingConstant.h12),
                    child: _OptionTile(
                      icon: Icons.medication_outlined,
                      label: med.name,
                      variant: _TileVariant.regular,
                      selected:
                          widget.hasSelection &&
                          widget.selectedName == med.name,
                      onTap: () => widget.onSelected(med.name),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Immutable spec for one of the two top actions, so the header delegate can
/// rebuild them in either the expanded or collapsed layout.
class _Action {
  const _Action({
    required this.icon,
    required this.label,
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _TileVariant variant;
  final bool selected;
  final VoidCallback onTap;
}

/// Collapsing header: full-size stacked buttons at rest, morphing into a
/// single compact row as it scrolls up and pins.
class _ActionsHeader extends SliverPersistentHeaderDelegate {
  _ActionsHeader(this.actions);

  final List<_Action> actions;

  // Expanded: top padding + two full tiles + the gap between them.
  double get _expanded =>
      AppSpacingConstant.h24 +
      AppSpacingConstant.h64 * 2 +
      AppSpacingConstant.h12;

  // Collapsed: the two actions side by side in one compact row.
  double get _collapsed => AppSpacingConstant.h56;

  @override
  double get maxExtent => _expanded;

  @override
  double get minExtent => _collapsed;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Cross-fade the two layouts; both anchor to the top so the taller
    // expanded one simply clips away under the shrinking box.
    return ClipRect(
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: t > 0.5,
                child: Opacity(opacity: 1 - t, child: _expandedLayout()),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: t <= 0.5,
                child: Opacity(opacity: t, child: _collapsedLayout()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedLayout() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w24,
        AppSpacingConstant.h24,
        AppSpacingConstant.w24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OptionTile.fromAction(actions[0]),
          SizedBox(height: AppSpacingConstant.h12),
          _OptionTile.fromAction(actions[1]),
        ],
      ),
    );
  }

  Widget _collapsedLayout() {
    return SizedBox(
      height: _collapsed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w24),
        child: Row(
          children: [
            Expanded(child: _OptionTile.fromAction(actions[0], compact: true)),
            SizedBox(width: AppSpacingConstant.w8),
            Expanded(child: _OptionTile.fromAction(actions[1], compact: true)),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ActionsHeader oldDelegate) {
    for (var i = 0; i < actions.length; i++) {
      if (oldDelegate.actions[i].selected != actions[i].selected ||
          oldDelegate.actions[i].label != actions[i].label) {
        return true;
      }
    }
    return false;
  }
}

enum _TileVariant { regular, destructive, positive }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.variant,
    required this.onTap,
  }) : compact = false;

  _OptionTile.fromAction(_Action a, {this.compact = false})
    : icon = a.icon,
      label = a.label,
      selected = a.selected,
      variant = a.variant,
      onTap = a.onTap;

  final IconData icon;
  final String label;
  final bool selected;
  final _TileVariant variant;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle = compact
        ? AppTextStyle.labelLarge
        : AppTextStyle.titleMedium;
    final button = selected
        ? AppButton.primary(
            onPressed: onTap,
            icon: icon,
            label: label,
            compact: compact,
            labelStyle: labelStyle,
          )
        : switch (variant) {
            _TileVariant.regular => AppButton.secondary(
              onPressed: onTap,
              icon: icon,
              label: label,
              compact: compact,
              labelStyle: labelStyle,
            ),
            _TileVariant.destructive => AppButton.destructive(
              onPressed: onTap,
              icon: icon,
              label: label,
              compact: compact,
              labelStyle: labelStyle,
            ),
            _TileVariant.positive => AppButton.positive(
              onPressed: onTap,
              icon: icon,
              label: label,
              compact: compact,
              labelStyle: labelStyle,
            ),
          };
    return SizedBox(
      height: compact ? AppSpacingConstant.h40 : AppSpacingConstant.h64,
      child: button,
    );
  }
}
