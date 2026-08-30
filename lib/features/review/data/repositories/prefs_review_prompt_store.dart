import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/review_prompt_state.dart';
import '../../domain/repositories/review_prompt_store.dart';

/// `SecureStore`, not the database: losing this costs at most one extra prompt, so it has no business in a table the sync engine has to carry.
class PrefsReviewPromptStore implements ReviewPromptStore {
  const PrefsReviewPromptStore(this._store);

  final SecureStore _store;

  @override
  Future<ReviewPromptState> read() async {
    final int count = _store.getInt(PrefsKeyConstant.reviewPromptCount) ?? 0;
    final String? raw = _store.getString(
      PrefsKeyConstant.reviewPromptLastAskedAt,
    );

    return ReviewPromptState(
      askCount: count,
      lastAskedAt: raw == null ? null : DateTime.tryParse(raw)?.toUtc(),
    );
  }

  @override
  Future<void> recordAsked(DateTime at) async {
    final int next =
        (_store.getInt(PrefsKeyConstant.reviewPromptCount) ?? 0) + 1;

    await _store.setInt(PrefsKeyConstant.reviewPromptCount, next);
    await _store.setString(
      PrefsKeyConstant.reviewPromptLastAskedAt,
      at.toUtc().toIso8601String(),
    );
    SdLogger.info(LogTagConstant.review, 'Review prompt recorded', {
      'askCount': next,
      'askedAt': at.toUtc().toIso8601String(),
    });
  }
}
