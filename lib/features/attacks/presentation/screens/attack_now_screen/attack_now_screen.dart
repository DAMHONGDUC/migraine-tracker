import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/attack.dart';
import '../../../providers.dart';
import '../../widgets/medication_picker_sheet.dart';

/// What the app is while an attack is running: a clock, and the two answers that are worth asking for mid-attack.
///
/// Deliberately the emptiest screen in the app. Everything here is either the
/// timer or a full-width target, because the person reading it is in pain and
/// photophobic (hard rule 3) — no cards, no readings, nothing to scroll past.
class AttackNowScreen extends ConsumerWidget {
  const AttackNowScreen({super.key});

  Future<void> _takeMedication(
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
          regions: attack.regions,
          medicationName: picked.name,
        );
    // The dose time is the point of asking here rather than on the detail screen: now is the only moment it is known without guessing.
    await ref
        .read(attackDetailControllerProvider)
        .updateMedicationTiming(
          attack.id,
          takenAt: DateTime.now().toUtc(),
          reliefAt: attack.reliefAt,
        );
  }

  Future<void> _end(BuildContext context, WidgetRef ref, Attack attack) async {
    final AppLocalizations l10n = context.l10n;

    await ref
        .read(attackDetailControllerProvider)
        .updateEndedAt(attack.id, DateTime.now().toUtc());
    if (!context.mounted) return;

    SdSnackBarUtilsV2.success(context, l10n.attackNowEndedToast);
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Attack? attack = ref.watch(attackInProgressProvider);

    // Ended from somewhere else, or aged out of the window while this was open.
    if (attack == null) {
      return SdScaffoldV2(
        title: Text(l10n.attackNowTitle, style: AppTextStyle.titleLarge),
        body: const SizedBox.shrink(),
      );
    }
    final Duration since =
        ref.watch(attackElapsedProvider(attack.startedAt)).value ??
        DateTime.now().toUtc().difference(attack.startedAt);

    return SdScaffoldV2(
      title: Text(l10n.attackNowTitle, style: AppTextStyle.titleLarge),
      body: Padding(
        padding: SdContentPaddingV2.screen(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Spacer(),
            // The one thing on the screen, and the only reason to open it.
            Text(
              DateTimeUtils.elapsed(since),
              textAlign: TextAlign.center,
              style: AppTextStyle.displaySmall,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              l10n.attackNowSince(
                DateFormat.Hm().format(attack.startedAt.toLocal()),
              ),
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Text(
              l10n.attackNowRest,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            // Offered only where nothing has been taken yet: a second dose is a decision this screen must not nudge.
            if (attack.medicationName == null) ...<Widget>[
              SdButtonV2(
                label: l10n.attackNowTookMedication,
                variant: SdButtonVariantV2.secondary,
                onPressed: () => _takeMedication(context, ref, attack),
              ),
              SizedBox(height: SdSpacingConstant.h8),
            ],
            SdButtonV2(
              label: l10n.attackNowEnded,
              variant: SdButtonVariantV2.primary,
              onPressed: () => _end(context, ref, attack),
            ),
          ],
        ),
      ),
    );
  }
}
