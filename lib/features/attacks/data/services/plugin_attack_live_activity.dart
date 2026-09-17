import 'dart:io';

import 'package:live_activities/live_activities.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/attack.dart';
import '../../domain/services/attack_live_activity.dart';

/// `live_activities`-backed [AttackLiveActivity].
///
/// The activity id is kept in [SecureStore] rather than in memory: the card
/// outlives the process, so a relaunch has to be able to take down the one the
/// last run started.
class PluginAttackLiveActivity implements AttackLiveActivity {
  PluginAttackLiveActivity(this._plugin, this._store, this._appGroupId);

  final LiveActivities _plugin;
  final SecureStore _store;
  final String _appGroupId;

  bool _initialized = false;

  @override
  Future<bool> get isAvailable async {
    if (!Platform.isIOS) return false;
    try {
      await _ensureInitialized();
      // Awaited, not returned bare: a Future handed out of the try block
      // settles outside it, so a refusal below iOS 16.1 would escape the catch
      // that exists to treat it as a device fact.
      return await _plugin.areActivitiesEnabled();
    } catch (error, stackTrace) {
      // Below 16.1 the channel simply refuses; that is a device fact, not a failure worth reporting.
      SdLogger.warning(
        LogTagConstant.attackLog,
        'Live Activities unavailable on this device',
        error,
      );
      SdLogger.debug(
        LogTagConstant.attackLog,
        'Live Activity stack',
        stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> start(
    Attack attack, {
    required String title,
    required String body,
  }) async {
    if (!await isAvailable) return;

    SdLogger.action(
      LogTagConstant.attackLog,
      'Start live activity',
      <String, Object?>{'attack': attack.id},
    );
    try {
      await _ensureInitialized();
      // The id is the attack's own, so a second start for the same attack refreshes the card instead of stacking a second one.
      await _plugin.createOrUpdateActivity(attack.id, <String, dynamic>{
        'title': title,
        'body': body,
        // Seconds, as a string: the extension rebuilds the Date and lets iOS tick the clock, so nothing here has to push an update a second.
        'startedAt': (attack.startedAt.millisecondsSinceEpoch ~/ 1000)
            .toString(),
      }, removeWhenAppIsKilled: false);
      await _store.setString(PrefsKeyConstant.liveActivityId, attack.id);
      SdLogger.info(
        LogTagConstant.attackLog,
        'Live activity started',
        attack.id,
      );
    } catch (error, stackTrace) {
      // The attack is already saved; a card that would not open costs nothing else.
      SdLogger.error(
        LogTagConstant.attackLog,
        'Starting the live activity failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'attack': attack.id},
      );
    }
  }

  @override
  Future<void> end() async {
    final String? id = _store.getString(PrefsKeyConstant.liveActivityId);

    if (id == null || !Platform.isIOS) return;

    SdLogger.action(LogTagConstant.attackLog, 'End live activity', id);
    try {
      await _ensureInitialized();
      await _plugin.endActivity(id);
      await _store.remove(PrefsKeyConstant.liveActivityId);
      SdLogger.info(LogTagConstant.attackLog, 'Live activity ended', id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackLog,
        'Ending the live activity failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'activity': id},
      );
    }
  }

  /// The plugin needs the App Group before anything else, and once per process is enough.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _plugin.init(appGroupId: _appGroupId);
    _initialized = true;
  }
}
