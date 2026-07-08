import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';
import '../widgets/intensity_step.dart';
import '../widgets/location_step.dart';
import '../widgets/medication_step.dart';
import '../widgets/saved_step.dart';

enum _LogStep { intensity, location, medication, saved }

/// The sacred 3-tap flow: intensity → head location → medication → saved.
/// No step may gain a required field without explicit approval.
class LogScreen extends HookConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final step = useState(_LogStep.intensity);
    final intensity = useState<int?>(null);
    final location = useState<HeadLocation?>(null);
    final savedId = useState<String?>(null);

    Future<void> save(String? medicationName) async {
      final attack = Attack(
        id: const Uuid().v4(),
        startedAt: DateTime.now().toUtc(),
        intensity: intensity.value!,
        location: location.value!,
        medicationName: medicationName,
      );
      await ref.read(attackRepositoryProvider).insert(attack);
      // Weather snapshot is fetched best-effort in the weather phase;
      // logging never waits for the network.
      savedId.value = attack.id;
      step.value = _LogStep.saved;
    }

    void reset() {
      intensity.value = null;
      location.value = null;
      savedId.value = null;
      step.value = _LogStep.intensity;
    }

    final title = switch (step.value) {
      _LogStep.intensity => l10n.logIntensityTitle,
      _LogStep.location => l10n.logLocationTitle,
      _LogStep.medication => l10n.logMedicationTitle,
      _LogStep.saved => l10n.logTitle,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: switch (step.value) {
          _LogStep.location => BackButton(
            onPressed: () => step.value = _LogStep.intensity,
          ),
          _LogStep.medication => BackButton(
            onPressed: () => step.value = _LogStep.location,
          ),
          _ => null,
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: switch (step.value) {
          _LogStep.intensity => IntensityStep(
            onSelected: (value) {
              intensity.value = value;
              step.value = _LogStep.location;
            },
          ),
          _LogStep.location => LocationStep(
            onSelected: (value) {
              location.value = value;
              step.value = _LogStep.medication;
            },
          ),
          _LogStep.medication => MedicationStep(onSelected: save),
          _LogStep.saved => SavedStep(attackId: savedId.value!, onDone: reset),
        },
      ),
    );
  }
}
