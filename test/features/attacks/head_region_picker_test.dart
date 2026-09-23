import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_diagram.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_geometry.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_grid.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_picker.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_scene_store.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/location_picker_sheet.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/location_step.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';
import 'package:system_design/index.dart';

import '../../helpers/settle_frames.dart';

/// The location step's two doors onto one answer, and the one-screen rule it has to keep: the head, the named tiles under it, and no scrolling anywhere.
void main() {
  late List<HeadRegion> selected;

  /// The height the log screen actually leaves `LocationStep` on a 393x852 phone, measured off the real tree rather than estimated.
  const double stepHeight = 706;

  Future<void> pumpPicker(
    WidgetTester tester, {
    List<HeadRegion> initial = const <HeadRegion>[],
    Size screen = const Size(393, 852),
    double height = stepHeight,
  }) async {
    tester.view.physicalSize = screen * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The flat pair is what a test draws, and it has to say so: a widget test
    // never resolves the model load, so the picker would otherwise sit on the
    // loading placeholder for the whole test.
    HeadSceneStore.markUnavailable();
    addTearDown(HeadSceneStore.reset);
    selected = initial;
    // The picker reads the saved zoom and rotation speed off `SecureStore`, so
    // a test needs one — an empty Keychain, which is what a first open sees.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    final SecureStore prefs = await SecureStore.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(prefs)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  height: height,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) =>
                        HeadRegionPicker(
                          selected: selected,
                          onChanged: (List<HeadRegion> regions) =>
                              setState(() => selected = regions),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the whole step fits one screen with nothing scrollable', (
    tester,
  ) async {
    await pumpPicker(tester);

    // Every scrollable in the tree must refuse to scroll: the grid shrink wraps, and nothing above it may add one either.
    for (final Scrollable scrollable in tester.widgetList<Scrollable>(
      find.byType(Scrollable),
    )) {
      expect(scrollable.physics, isA<NeverScrollableScrollPhysics>());
    }
    expect(tester.takeException(), isNull);
  });

  /// Scoped to the grid: the summary line under it spells the same areas out, so a bare text finder matches twice.
  Finder tile(String label) => find.descendant(
    of: find.byType(HeadRegionGrid),
    matching: find.text(label),
  );

  testWidgets('fallback keeps anatomical labels and hides unsupported zoom', (
    WidgetTester tester,
  ) async {
    await pumpPicker(tester);
    await tester.pump();
    expect(find.byTooltip('Zoom in'), findsNothing);
    expect(
      tester.getCenter(find.text('L')).dx,
      lessThan(tester.getCenter(find.text('R')).dx),
    );
    await tester.tap(find.text('Back'));
    await settleFrames(tester);
    expect(
      tester.getCenter(find.text('L')).dx,
      lessThan(tester.getCenter(find.text('R')).dx),
    );
    await tester.tap(tile('Nape'));
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.nape]);
  });

  testWidgets('Deselect all clears both sides and leaves the head in place', (
    WidgetTester tester,
  ) async {
    await pumpPicker(
      tester,
      initial: <HeadRegion>[HeadRegion.values.first, HeadRegion.nape],
    );
    await tester.pump();
    final Rect head = tester.getRect(find.byType(HeadDiagram));

    await tester.tap(find.text('Deselect all'));
    await tester.pump();

    expect(selected, isEmpty);
    // Nothing left to clear, so the button goes — and the head stays put.
    expect(find.text('Deselect all'), findsNothing);
    expect(tester.getRect(find.byType(HeadDiagram)), head);
  });

  testWidgets('picker fits a short edit sheet', (WidgetTester tester) async {
    await pumpPicker(tester, height: 500);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HeadDiagram)).height, greaterThan(0));
    await tester.tap(find.text('Back'));
    await settleFrames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tile and the head write the same answer', (tester) async {
    await pumpPicker(tester);

    await tester.tap(tile('Left temple'));
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.templeL]);

    // Tapping it again clears it — the tiles toggle exactly like the bands.
    await tester.tap(tile('Left temple'));
    await tester.pump();
    expect(selected, isEmpty);
  });

  testWidgets('the tiles follow the view the head is showing', (tester) async {
    await pumpPicker(tester, initial: <HeadRegion>[HeadRegion.nape]);

    // Opens on the back, because that is where the picked area lives.
    expect(tile('Nape'), findsOneWidget);
    expect(tile('Left cheek'), findsNothing);

    await tester.tap(find.text('Front'));
    // Settled, not pumped: the tabs turn the head rather than cutting to it,
    // and the tiles follow the side that ends up facing.
    await tester.pumpAndSettle();

    expect(tile('Left cheek'), findsOneWidget);
    expect(tile('Nape'), findsNothing);
  });

  testWidgets('the head keeps its size and its place on both views', (
    tester,
  ) async {
    await pumpPicker(tester);
    final Rect front = tester.getRect(find.byType(HeadDiagram));

    await tester.tap(find.text('Back'));
    await settleFrames(tester);

    // The back view has four tiles to the front's eleven.
    expect(tester.getRect(find.byType(HeadDiagram)), front);
  });

  testWidgets('the drawing fills the box it was given', (tester) async {
    await pumpPicker(tester);

    // The bug this exists for: AnimatedSwitcher stacks its children under loose constraints, so the SVG drew at the asset's own 200x248 inside a box twice.
    expect(
      tester.getRect(
        find.descendant(
          of: find.byType(HeadDiagram),
          matching: find.byType(SvgPicture),
        ),
      ),
      tester.getRect(find.byType(HeadDiagram)),
    );
  });

  testWidgets('the head keeps its aspect and stays inside the screen', (
    tester,
  ) async {
    await pumpPicker(tester);
    final Rect head = tester.getRect(find.byType(HeadDiagram));

    // The drawing is 200x248, and it must never be stretched to fill a box that is not — a head squashed sideways is worse than a small one.
    expect(head.width / head.height, closeTo(200 / 248, 0.01));
    expect(head.width, lessThanOrEqualTo(393));
  });

  testWidgets('the head is sized from its width, w24 either side', (
    tester,
  ) async {
    await pumpPicker(tester, height: 820);

    final Rect head = tester.getRect(find.byType(HeadDiagram));
    final Rect grid = tester.getRect(find.byType(HeadRegionGrid));
    // The owner's number, read from the constant rather than copied: it has moved twice (40 → 30 → 24) and a literal here fails on the move rather than on the ring going uneven, which is what the test is for.
    final double inset = SdSpacingConstant.w24;

    // Derive height from the width so the head stays aligned.
    expect(head.left, inset);
    expect(head.width, 393 - inset * 2);
    expect(head.height, closeTo(head.width / (200 / 248), 0.5));
    // Never closer to the tiles than the ring either side of it.
    expect(grid.top - head.bottom, greaterThanOrEqualTo(inset - 0.5));
    expect(grid.height, greaterThan(HeadRegionGrid.reservedHeight));

    // And centred in what the tabs and the tiles leave (owner's rule,
    // 2026-09-19): the air above the head is the air below it, the gap before
    // the tiles aside. The tiles are pinned to the bottom of the step, so a
    // tall screen gives the difference to the head rather than to a hole.
    // Measured off the ROW, not off the tabs' own pill: the pill is 42 in a
    // 44pt row and sits centred in it, so its bottom edge is 1pt short of
    // where the head's air actually starts.
    final Rect tabs = tester.getRect(find.byType(SdSegmentedTabsV2));
    final double rowBottom =
        tabs.bottom + (HeadRegionPicker.topRowHeight - tabs.height) / 2;

    expect(head.top - rowBottom, closeTo(grid.top - inset - head.bottom, 0.5));
  });

  testWidgets('the nose is its own area, and the cheek stops at it', (
    tester,
  ) async {
    await pumpPicker(tester);

    // One area, no L/R pair: it sits ON the midline rather than either side of it.
    await tester.tap(tile('Nose'));
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.nose]);

    // And the areas around it are cut to its outline, not run under it: the tip of the nose is the nose, from either side of the face.
    const Size design = HeadRegionGeometry.designSize;
    for (final Offset point in <Offset>[
      const Offset(96, 130), // bridge, left of centre
      const Offset(104, 130), // bridge, right of centre
      const Offset(100, 168), // the tip, below the under-eye cut
    ]) {
      expect(
        HeadRegionGeometry.hitTest(point, HeadView.front, design),
        HeadRegion.nose,
        reason: 'design point $point should be the nose',
      );
    }
  });

  /// The same tree the step and the sheet are pumped in, so the only
  /// difference between the two measurements is the widget under test.
  Future<void> pumpHosted(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    HeadSceneStore.markUnavailable();
    addTearDown(HeadSceneStore.reset);
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    final SecureStore prefs = await SecureStore.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(prefs)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the edit sheet lays the picker out exactly as the step does', (
    WidgetTester tester,
  ) async {
    // The sheet's own gutter would land on top of the picker's, so the tiles
    // came out 16pt narrower there than in the flow — same widget, two
    // paddings. It hands the step the full width instead.
    await pumpHosted(
      tester,
      LocationStep(
        selected: const <HeadRegion>[],
        onChanged: (List<HeadRegion> regions) {},
      ),
    );

    final Rect stepGrid = tester.getRect(find.byType(HeadRegionGrid));

    await pumpHosted(
      tester,
      const LocationPickerSheet(selected: <HeadRegion>[]),
    );

    final Rect sheetGrid = tester.getRect(find.byType(HeadRegionGrid));

    expect(sheetGrid.left, stepGrid.left);
    expect(sheetGrid.width, stepGrid.width);
    expect(stepGrid.left, SdContentPaddingV2.horizontal);
  });

  // The picker's one-screen rule reaches the SHEET too, and there it is not a
  // layout preference: on iOS a scroll view rubber-bands even when its content
  // fits, and its vertical drag competes with the drag that turns the head —
  // so turning the head bounced the sheet's content under the same finger.
  testWidgets('the edit sheet has nothing that can scroll either', (
    WidgetTester tester,
  ) async {
    await pumpHosted(
      tester,
      const LocationPickerSheet(selected: <HeadRegion>[]),
    );

    final Iterable<Scrollable> scrollables = tester.widgetList<Scrollable>(
      find.descendant(
        of: find.byType(LocationPickerSheet),
        matching: find.byType(Scrollable),
      ),
    );

    expect(scrollables, isNotEmpty, reason: 'the grid is one');
    for (final Scrollable scrollable in scrollables) {
      expect(scrollable.physics, isA<NeverScrollableScrollPhysics>());
    }
  });

  testWidgets('the head is still tappable beside the tiles', (tester) async {
    await pumpPicker(tester);

    // The crown: the top of the drawing, which is the one band no other area can be confused with on either view.
    final Rect head = tester.getRect(find.byType(HeadDiagram));
    await tester.tapAt(Offset(head.center.dx, head.top + head.height * 0.06));
    await tester.pump();

    expect(selected, <HeadRegion>[HeadRegion.crown]);
  });
}
