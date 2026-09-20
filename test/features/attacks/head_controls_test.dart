import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_rotation_speed.dart';
import 'package:migraine_tracker/features/attacks/presentation/controllers/head_controls_controller.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_viewport.dart';
import 'package:migraine_tracker/features/attacks/providers.dart';

/// The head's camera controls, and the one thing that makes them worth having:
/// they are still there on the next launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container([
    Map<String, String> stored = const <String, String>{},
  ]) async {
    // A copy, not the caller's map: the mock platform writes into the very
    // map it is handed, and a `const` one throws on the first save.
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(stored));

    final SecureStore prefs = await SecureStore.open();
    final ProviderContainer container = ProviderContainer(
      overrides: [secureStoreProvider.overrideWithValue(prefs)],
    );

    addTearDown(container.dispose);

    return container;
  }

  test(
    'a first open gets the default zoom and the full rotation speed',
    () async {
      final ProviderContainer ref = await container();
      final HeadControls controls = ref.read(headControlsProvider);

      expect(controls.zoom, HeadViewportUtils.defaultZoom);
      expect(controls.rotationSpeed, HeadRotationSpeed.full);
    },
  );

  test('what the last session left is what the next one opens at', () async {
    final ProviderContainer ref = await container(<String, String>{
      PrefsKeyConstant.headZoom: '1.25',
      PrefsKeyConstant.headRotationSpeed: '50',
    });
    final HeadControls controls = ref.read(headControlsProvider);

    expect(controls.zoom, 1.25);
    expect(controls.rotationSpeed, HeadRotationSpeed.slow);
  });

  test('a stored zoom outside the ladder is clamped onto it', () async {
    final ProviderContainer ref = await container(<String, String>{
      PrefsKeyConstant.headZoom: '9',
    });

    expect(ref.read(headControlsProvider).zoom, HeadViewportUtils.maxZoom);
  });

  test('the speed button steps down and wraps back to full', () async {
    final ProviderContainer ref = await container();
    final HeadControlsController controls = ref.read(
      headControlsProvider.notifier,
    );

    controls.reduceRotationSpeed();
    expect(
      ref.read(headControlsProvider).rotationSpeed,
      HeadRotationSpeed.reduced,
    );

    controls.reduceRotationSpeed();
    expect(
      ref.read(headControlsProvider).rotationSpeed,
      HeadRotationSpeed.slow,
    );

    // The way back: one button, one direction, and the bottom leads home.
    controls.reduceRotationSpeed();
    expect(
      ref.read(headControlsProvider).rotationSpeed,
      HeadRotationSpeed.full,
    );
  });

  test('a change reaches the store once it settles', () async {
    final ProviderContainer ref = await container();

    ref.read(headControlsProvider.notifier)
      ..setZoom(2)
      ..reduceRotationSpeed();

    // Nothing yet: a pinch writes when the fingers stop, not per frame.
    expect(
      ref.read(secureStoreProvider).getDouble(PrefsKeyConstant.headZoom),
      isNull,
    );

    await Future<void>.delayed(
      HeadControlsController.settle + const Duration(milliseconds: 100),
    );

    final SecureStore prefs = ref.read(secureStoreProvider);

    expect(prefs.getDouble(PrefsKeyConstant.headZoom), 2);
    expect(
      prefs.getInt(PrefsKeyConstant.headRotationSpeed),
      HeadRotationSpeed.reduced.percent,
    );
  });
}
