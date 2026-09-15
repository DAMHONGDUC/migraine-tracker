import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/midas_grade_label.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/midas_score.dart';
import '../../../providers.dart';
import '../../controllers/midas_controller.dart';

part 'midas_screen_question.dart';

/// The MIDAS questionnaire: five day-counts, and the total a neurologist reads.
///
/// MIDAS alone, never HIT-6 beside it — that one is licensed
/// (`docs/rules/DECISIONS.md`). The two unscored MIDAS questions (headache days
/// and average pain) are left out: the app already counts the days, and asking
/// for a number it holds invites a worse one.
class MidasScreen extends HookConsumerWidget {
  const MidasScreen({super.key});

  static const List<String> _noteKeys = <String>['', 'q2', '', 'q4', ''];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final MidasDraft draft = ref.watch(midasControllerProvider);
    final MidasEntry? previous = ref.watch(latestMidasProvider).value;
    final List<String> questions = <String>[
      l10n.midasQ1,
      l10n.midasQ2,
      l10n.midasQ3,
      l10n.midasQ4,
      l10n.midasQ5,
    ];

    // Once per mount: after that the screen owns the numbers, and re-loading would undo what the user just typed.
    useEffect(() {
      ref.read(midasControllerProvider.notifier).loadFrom(previous);
      return null;
    }, const <Object?>[]);

    Future<void> save() async {
      try {
        await ref.read(midasControllerProvider.notifier).save();
        if (!context.mounted) return;

        SdSnackBarUtilsV2.success(context, l10n.midasSaved);
        context.pop();
      } catch (_) {
        // Already logged by the controller; the screen's job is to say so.
        if (!context.mounted) return;
        SdSnackBarUtilsV2.error(context, l10n.midasSaveFailed);
      }
    }

    return SdScaffoldV2(
      title: Text(l10n.midasTitle, style: AppTextStyle.titleLarge),
      body: ListView(
        padding: SdContentPaddingV2.screen(context),
        children: <Widget>[
          Text(
            l10n.midasIntro,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          for (final (int index, String question) in questions.indexed) ...[
            _Question(
              question: question,
              note: switch (_noteKeys[index]) {
                'q2' => l10n.midasQ2Note,
                'q4' => l10n.midasQ4Note,
                _ => null,
              },
              days: draft.answers[index],
              onChanged: (int days) => ref
                  .read(midasControllerProvider.notifier)
                  .answer(index, days),
            ),
            SizedBox(height: SdContentPaddingV2.sectionGap),
          ],
          _Total(score: draft.score),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          SdButtonV2(
            label: l10n.midasSave,
            variant: SdButtonVariantV2.primary,
            onPressed: save,
          ),
        ],
      ),
    );
  }
}
