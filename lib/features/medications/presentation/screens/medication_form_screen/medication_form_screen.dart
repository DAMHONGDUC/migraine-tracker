import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/medication_draft.dart';
import '../../../domain/services/medication_photo_source.dart';
import '../../../providers.dart';
import '../../widgets/medication_scan_source_sheet.dart';

part 'medication_form_screen_field.dart';

/// The long way to add a medication: a name, and anything else off the box
/// the user cares to keep.
///
/// Only the name is required — everything below it is optional and free
/// text, and the screen saves happily with all of it empty. The scan button
/// fills the same fields from a photo of the label; it never saves, so a
/// misread never becomes a medication on its own.
class MedicationFormScreen extends HookConsumerWidget {
  const MedicationFormScreen({super.key});

  /// Trimmed, or null when the user left it blank — the entity's "not filled
  /// in" is null, never an empty string.
  String? _valueOf(TextEditingController controller) {
    final String value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final TextEditingController name = useTextEditingController();
    final TextEditingController description = useTextEditingController();
    final TextEditingController ingredients = useTextEditingController();
    final TextEditingController strength = useTextEditingController();
    final TextEditingController dosage = useTextEditingController();
    final TextEditingController instructions = useTextEditingController();
    // Only the name gates the save button, so only the name has to rebuild it.
    final ValueNotifier<bool> canSave = useState(false);
    final ValueNotifier<bool> scanning = useState(false);

    useEffect(() {
      void listener() => canSave.value = name.text.trim().isNotEmpty;

      name.addListener(listener);
      return () => name.removeListener(listener);
    }, <Object>[name]);

    Future<void> scan() async {
      final MedicationPhotoOrigin? origin =
          await const MedicationScanSourceSheet().show(context);

      if (origin == null || !context.mounted) return;

      scanning.value = true;
      try {
        final MedicationDraft? draft = await ref
            .read(medicationScanControllerProvider)
            .scan(origin);

        if (!context.mounted || draft == null) return;

        if (draft.isEmpty) {
          SdSnackBarUtilsV2.info(context, l10n.medicationScanNothingFound);
          return;
        }

        // Fill only what the label actually said, and only where the user has
        // not typed something already — a scan assists, it never overwrites.
        _fill(name, draft.name);
        _fill(description, draft.description);
        _fill(ingredients, draft.ingredients);
        _fill(strength, draft.strength);
        _fill(dosage, draft.dosage);
        _fill(instructions, draft.instructions);
        canSave.value = name.text.trim().isNotEmpty;
        SdSnackBarUtilsV2.success(context, l10n.medicationScanFilled);
      } catch (_) {
        // The controller already logged and reported it; the user needs the
        // outcome and their typing back, untouched.
        if (context.mounted) {
          SdSnackBarUtilsV2.error(context, l10n.medicationScanFailed);
        }
      } finally {
        scanning.value = false;
      }
    }

    Future<void> save() async {
      await ref
          .read(medicationsControllerProvider)
          .add(
            name.text.trim(),
            description: _valueOf(description),
            ingredients: _valueOf(ingredients),
            strength: _valueOf(strength),
            dosage: _valueOf(dosage),
            instructions: _valueOf(instructions),
          );
      if (context.mounted && context.canPop()) context.pop();
    }

    return SdScaffoldV2(
      title: Text(l10n.medicationFormTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SdButtonV2(
              variant: SdButtonVariantV2.outlined,
              icon: Icons.document_scanner_outlined,
              onPressed: scanning.value ? null : scan,
              label: scanning.value
                  ? l10n.medicationScanReading
                  : l10n.medicationScanAction,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              l10n.medicationScanHint,
              style: AppTextStyle.bodySmall.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h24),

            _FormField(
              controller: name,
              label: l10n.medicationFormName,
              hint: l10n.medicationFormNameHint,
              autofocus: true,
            ),
            _FormField(
              controller: description,
              label: l10n.medicationFormDescription,
              hint: l10n.medicationFormDescriptionHint,
              maxLines: 2,
            ),
            _FormField(
              controller: ingredients,
              label: l10n.medicationFormIngredients,
              hint: l10n.medicationFormIngredientsHint,
            ),
            _FormField(
              controller: strength,
              label: l10n.medicationFormStrength,
              hint: l10n.medicationFormStrengthHint,
            ),
            _FormField(
              controller: dosage,
              label: l10n.medicationFormDosage,
              hint: l10n.medicationFormDosageHint,
            ),
            _FormField(
              controller: instructions,
              label: l10n.medicationFormInstructions,
              hint: l10n.medicationFormInstructionsHint,
              maxLines: 2,
            ),
          ],
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            onPressed: canSave.value ? save : null,
            label: l10n.detailsSave,
          ),
        ],
      ),
    );
  }

  /// Writes [value] into [controller] unless the user already typed there.
  void _fill(TextEditingController controller, String? value) {
    if (value == null || controller.text.trim().isNotEmpty) return;
    controller.text = value;
  }
}
