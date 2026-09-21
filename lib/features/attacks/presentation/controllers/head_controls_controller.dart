import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/enums/head_rotation_speed.dart';
import '../widgets/head_viewport.dart';

/// How the head picker is driven: the magnification it opens at, and how far
/// a drag turns it.
///
/// **A null [zoom] is "never chosen", not "zero"** — the picker then opens at
/// whatever fills the viewport it was handed (`HeadViewportUtils.fitZoom`).
/// A number here is one the user set themselves, and it outranks the fit,
/// because someone who zoomed out to see the whole head did not mean it for
/// one screen only.
typedef HeadControls = ({double? zoom, HeadRotationSpeed rotationSpeed});

/// The picker's camera controls, kept across launches (owner's rule,
/// 2026-09-19).
///
/// **Presentation state that happens to be persisted — never attack data.**
/// Nothing here says where anybody hurts, so it is not synced, not exported
/// and not part of an `Attack`; it is kept only because someone who slowed the
/// turn down or zoomed in did it once, and an app that forgets that asks them
/// again on the next attack — which is the worst moment to be adjusting a
/// control.
///
/// The angle is deliberately NOT kept. Which way the head is facing is the
/// Front/Back tab's answer and is decided per attack by what is already
/// selected, so restoring yesterday's angle would open the picker somewhere
/// nobody chose.
class HeadControlsController extends Notifier<HeadControls> {
  /// How long a change waits before it reaches the Keychain.
  ///
  /// A pinch changes the zoom on every pointer frame; without this the store
  /// would take a write per frame for a value only the last of which matters.
  /// Long enough for fingers to stop, short enough that leaving the step right
  /// after still keeps the level.
  ///
  /// Public because `head_controls_test.dart` waits it out rather than
  /// sleeping on a number of its own — the two drifting apart is a test that
  /// passes by luck.
  static const Duration settle = Duration(milliseconds: 400);

  Timer? _pending;

  /// What the pending timer is going to write, and the store it belongs to —
  /// captured at the moment it was scheduled rather than read back when it
  /// fires. A flush on dispose has no `state` and no `ref` left to ask.
  ({SecureStore prefs, HeadControls controls})? _unsaved;

  @override
  HeadControls build() {
    final SecureStore prefs = ref.watch(secureStoreProvider);

    // Alive for the session (Riverpod 3 disposes an unwatched provider by
    // default): the log flow and the detail screen's edit sheet are two
    // pickers that must open at the same zoom, and a provider torn down
    // between them would reread the store on every mount to say so.
    ref.keepAlive();
    ref.onDispose(() {
      _pending?.cancel();
      // A picker closed inside the debounce window keeps what it was left
      // at anyway: Next is tapped a frame after the last pinch more often
      // than not, and a setting that survives only a slow exit is worse
      // than one that is never kept.
      unawaited(_flush());
    });

    return (
      // Clamped on the way in: the ladder's ends have moved before, and a
      // stored level outside them would open the picker at a magnification
      // its own buttons cannot walk back from. Null stays null — that is the
      // picker's cue to measure the viewport instead.
      zoom: prefs
          .getDouble(PrefsKeyConstant.headZoom)
          ?.clamp(HeadViewportUtils.minZoom, HeadViewportUtils.maxZoom),
      rotationSpeed: HeadRotationSpeed.fromPercent(
        prefs.getInt(PrefsKeyConstant.headRotationSpeed),
      ),
    );
  }

  /// The zoom the user is now looking at. On screen immediately, in the store
  /// once it settles.
  void setZoom(double zoom) {
    if (zoom == state.zoom) return;

    state = (zoom: zoom, rotationSpeed: state.rotationSpeed);
    _scheduleSave();
  }

  /// Forgets the user's level, so the picker goes back to measuring the
  /// viewport — what Reset means.
  ///
  /// It deletes the key rather than storing the fit it is going back to: the
  /// fit belongs to one viewport, and writing it would turn "open as large as
  /// this screen allows" back into a number, which is the thing this replaced.
  void clearZoom() {
    if (state.zoom == null) return;

    state = (zoom: null, rotationSpeed: state.rotationSpeed);
    _pending?.cancel();
    _unsaved = null;
    unawaited(_forget(ref.read(secureStoreProvider)));
  }

  Future<void> _forget(SecureStore prefs) async {
    try {
      await prefs.remove(PrefsKeyConstant.headZoom);
      SdLogger.info(LogTagConstant.attackLog, 'Head zoom forgotten');
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackLog,
        'Head zoom forget failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// One step down the [HeadRotationSpeed] ladder, wrapping at the bottom.
  void reduceRotationSpeed() {
    final HeadRotationSpeed next = state.rotationSpeed.slower;

    SdLogger.action(
      LogTagConstant.attackLog,
      'Change head rotation speed',
      <String, Object?>{'percent': next.percent},
    );
    state = (zoom: state.zoom, rotationSpeed: next);
    _scheduleSave();
  }

  void _scheduleSave() {
    _unsaved = (prefs: ref.read(secureStoreProvider), controls: state);
    _pending?.cancel();
    _pending = Timer(settle, _flush);
  }

  /// Writes both values, and never throws.
  ///
  /// A Keychain that refuses the write costs the next launch its saved
  /// controls, which is a worse picker rather than a broken one — so this
  /// logs and swallows instead of letting a timer callback take the zone down.
  Future<void> _flush() async {
    final ({SecureStore prefs, HeadControls controls})? pending = _unsaved;

    if (pending == null) return;

    _unsaved = null;

    final HeadControls controls = pending.controls;
    final SecureStore prefs = pending.prefs;

    final double? zoom = controls.zoom;

    try {
      // Null only when the rotation speed changed before anyone touched the
      // zoom; the key stays absent rather than being written as a level.
      if (zoom != null) {
        await prefs.setDouble(PrefsKeyConstant.headZoom, zoom);
      }
      await prefs.setInt(
        PrefsKeyConstant.headRotationSpeed,
        controls.rotationSpeed.percent,
      );
      SdLogger.info(
        LogTagConstant.attackLog,
        'Head controls saved',
        <String, Object?>{
          'zoom': controls.zoom,
          'rotationPercent': controls.rotationSpeed.percent,
        },
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackLog,
        'Head controls save failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'zoom': controls.zoom,
          'rotationPercent': controls.rotationSpeed.percent,
        },
      );
    }
  }
}
