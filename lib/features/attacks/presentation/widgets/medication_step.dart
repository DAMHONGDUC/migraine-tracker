import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/providers.dart';

/// Third tap: which medication was taken (or none). Selecting saves the
/// attack immediately — this is the last step of the sacred 3-tap flow.
class MedicationStep extends ConsumerWidget {
  const MedicationStep({required this.onSelected, super.key});

  /// Called with the medication name, or null for "no medication".
  final ValueChanged<String?> onSelected;

  Future<void> _addMedication(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logAddMedication),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.logMedicationNameHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await ref
        .read(medicationRepositoryProvider)
        .upsert(Medication(id: const Uuid().v4(), name: trimmed));
    // Mid-attack every tap counts: adding a medication also selects it.
    onSelected(trimmed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final medications = ref.watch(medicationsStreamProvider);

    return ListView(
      padding: EdgeInsets.all(24.w),
      children: [
        _OptionTile(
          icon: Icons.close,
          label: l10n.logNoMedication,
          onTap: () => onSelected(null),
        ),
        SizedBox(height: 12.h),
        for (final med in medications.value ?? <Medication>[]) ...[
          _OptionTile(
            icon: Icons.medication_outlined,
            label: med.name,
            onTap: () => onSelected(med.name),
          ),
          SizedBox(height: 12.h),
        ],
        _OptionTile(
          icon: Icons.add,
          label: l10n.logAddMedication,
          onTap: () => _addMedication(context, ref),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: context.textTheme.titleMedium),
      ),
    );
  }
}
