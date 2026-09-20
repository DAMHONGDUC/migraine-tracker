import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/data/repositories/error_view_mapper.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/error_view_config.dart';
import 'package:migraine_tracker/features/app_config/domain/enums/error_view_type.dart';

import '../../helpers/pump_app.dart';

/// The notice replaces the whole app, so these guard the case that matters
/// most: it must NOT appear unless the owner switched it on and wrote it.
void main() {
  group('ErrorViewMapper', () {
    test('reads a switched-on section in full', () {
      final ErrorViewConfig? config = ErrorViewMapper.fromMap(
        <String, Object?>{
          'enable': true,
          'title': 'We are down',
          'subtitle_1': 'The backend is being repaired.',
          'subtitle_2': 'Your logs are safe on this device.',
          'type': 'warning',
        },
      );

      expect(config?.title, 'We are down');
      expect(config?.subtitle1, 'The backend is being repaired.');
      expect(config?.subtitle2, 'Your logs are safe on this device.');
      expect(config?.type, ErrorViewType.warning);
    });

    test('the subtitles are optional', () {
      final ErrorViewConfig? config = ErrorViewMapper.fromMap(
        <String, Object?>{'enable': true, 'title': 'We are down'},
      );

      expect(config?.subtitle1, isEmpty);
      expect(config?.subtitle2, isEmpty);
    });

    // A notice that could be switched on by a typo is one that takes the app
    // away by typo.
    test('anything but an explicit true is off', () {
      for (final Object? enable in <Object?>[
        null,
        false,
        'true',
        1,
        <String>[],
      ]) {
        expect(
          ErrorViewMapper.fromMap(<String, Object?>{
            'enable': enable,
            'title': 'We are down',
          }),
          isNull,
          reason: 'enable: $enable must not show the notice',
        );
      }
    });

    // Replacing a working app with a screen that says nothing is worse than
    // not showing it at all.
    test('a notice with nothing to say is dropped', () {
      expect(
        ErrorViewMapper.fromMap(const <String, Object?>{'enable': true}),
        isNull,
      );
      expect(
        ErrorViewMapper.fromMap(const <String, Object?>{
          'enable': true,
          'title': '   ',
        }),
        isNull,
      );
    });

    // The notice is already being shown on purpose, so a typo in `type` must
    // not quietly downgrade an outage to a warning.
    test('an unreadable type falls back to the louder one', () {
      for (final Object? type in <Object?>[null, 'WARN', 'critical', 7]) {
        expect(
          ErrorViewMapper.fromMap(<String, Object?>{
            'enable': true,
            'title': 'We are down',
            'type': type,
          })?.type,
          ErrorViewType.error,
          reason: 'type: $type must read as error',
        );
      }
    });

    test('the type is read whatever case the owner typed', () {
      expect(
        ErrorViewMapper.fromMap(const <String, Object?>{
          'enable': true,
          'title': 'We are down',
          'type': ' Warning ',
        })?.type,
        ErrorViewType.warning,
      );
    });
  });

  group('the gate', () {
    testWidgets('no notice leaves the app alone', (tester) async {
      await pumpApp(tester);

      expect(find.text('Log an attack'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('a notice replaces the app, for an anonymous session too', (
      tester,
    ) async {
      await pumpApp(
        tester,
        appConfig: AppConfig(
          errorView: const ErrorViewConfig(
            title: 'We are down',
            subtitle1: 'The backend is being repaired.',
            subtitle2: 'Your logs are safe on this device.',
            type: ErrorViewType.error,
          ),
        ),
      );

      expect(find.text('We are down'), findsOneWidget);
      expect(find.text('The backend is being repaired.'), findsOneWidget);
      expect(find.text('Your logs are safe on this device.'), findsOneWidget);
      expect(find.text('Log an attack'), findsNothing);

      await finishTest(tester);
    });
  });
}
