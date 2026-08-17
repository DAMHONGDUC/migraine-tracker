import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../domain/entities/review_prompt_state.dart';
import '../../domain/repositories/review_prompt_store.dart';

/// Prefs, not the database: losing this costs at most one extra prompt, so it
/// has no business in a table the sync engine has to carry.
class PrefsReviewPromptStore implements ReviewPromptStore {
  const PrefsReviewPromptStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<ReviewPromptState> read() async {
    final int count = _prefs.getInt(PrefsKeyConstant.reviewPromptCount) ?? 0;
    final String? raw = _prefs.getString(
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
        (_prefs.getInt(PrefsKeyConstant.reviewPromptCount) ?? 0) + 1;

    await _prefs.setInt(PrefsKeyConstant.reviewPromptCount, next);
    await _prefs.setString(
      PrefsKeyConstant.reviewPromptLastAskedAt,
      at.toUtc().toIso8601String(),
    );
    SdLogger.info(LogTagConstant.review, 'Review prompt recorded', {
      'askCount': next,
      'askedAt': at.toUtc().toIso8601String(),
    });
  }
}
