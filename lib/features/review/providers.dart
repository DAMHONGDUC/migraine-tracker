import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../core/storage/secure_store.dart';
import 'data/repositories/prefs_review_prompt_store.dart';
import 'data/services/in_app_review_prompter.dart';
import 'domain/repositories/review_prompt_store.dart';
import 'domain/services/review_prompter.dart';
import 'presentation/controllers/review_prompt_controller.dart';

final reviewPromptStoreProvider = Provider<ReviewPromptStore>(
  (ref) => PrefsReviewPromptStore(ref.watch(secureStoreProvider)),
);

/// Overridden with a fake in `pumpApp`: the log flow reaches this on every saved attack, and the real one calls a platform channel no widget test has.
final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => InAppReviewPrompter(InAppReview.instance),
);

/// Turns a value moment into a prompt (see [ReviewPromptController]).
final reviewPromptControllerProvider = Provider<ReviewPromptController>(
  ReviewPromptController.new,
);
