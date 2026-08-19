import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_diagram.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_geometry.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_grid.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_picker.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

/// The location step's two doors onto one answer, and the one-screen rule it
/// has to keep: the head, the named tiles under it, and no scrolling
/// anywhere.
void main() {
  late List<HeadRegion> selected;

  /// The height the log screen actually leaves `LocationStep` on a 393x852
  /// phone, measured off the real tree rather than estimated: app bar,
  /// status bar and the floating step bar taken off. If the picker ever
  /// stops fitting in this, the step scrolls on a real device.
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
    selected = initial;

    await tester.pumpWidget(
      ScreenUtilInit(
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
    );
  }

  testWidgets('the whole step fits one screen with nothing scrollable', (
    tester,
  ) async {
    await pumpPicker(tester);

    // Every scrollable in the tree must refuse to scroll: the grid shrink
    // wraps, and nothing above it may add one either.
    for (final Scrollable scrollable
        in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
      expect(scrollable.physics, isA<NeverScrollableScrollPhysics>());
    }
    expect(tester.takeException(), isNull);
  });

  /// Scoped to the grid: the summary line under it spells the same areas
  /// out, so a bare text finder matches twice.
  Finder tile(String label) => find.descendant(
    of: find.byType(HeadRegionGrid),
    matching: find.text(label),
  );

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
    await tester.pump();

    expect(tile('Left cheek'), findsOneWidget);
    expect(tile('Nape'), findsNothing);
  });

  testWidgets('the head keeps its size and its place on both views', (
    tester,
  ) async {
    await pumpPicker(tester);
    final Rect front = tester.getRect(find.byType(HeadDiagram));

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    // The back view has four tiles to the front's eleven. The grid reserves
    // the taller of the two either way, or the difference would land on the
    // diagram above it.
    expect(tester.getRect(find.byType(HeadDiagram)), front);
  });

  testWidgets('the drawing fills the box it was given', (tester) async {
    await pumpPicker(tester);

    // The bug this exists for: AnimatedSwitcher lays its children out in a
    // Stack, which hands them loose constraints, so the SVG drew itself at
    // the asset's own 200x248 and sat marooned in the middle of a box twice
    // that size. Every attempt to make the head bigger changed the box and
    // nothing the user could see — and worse, taps were mapped against the
    // box while the head was drawn to the asset, so they landed in the wrong
    // area entirely.
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

    // The drawing is 200x248, and it must never be stretched to fill a box
    // that is not — a head squashed sideways is worse than a small one.
    expect(head.width / head.height, closeTo(200 / 248, 0.01));
    expect(head.width, lessThanOrEqualTo(393));
  });

  testWidgets('the head is sized from its width, 30 either side', (
    tester,
  ) async {
    await pumpPicker(tester, height: 820);

    final Rect head = tester.getRect(find.byType(HeadDiagram));
    final Rect grid = tester.getRect(find.byType(HeadRegionGrid));

    // Owner's rule: 30 in from each edge, and the height follows from that
    // width — never the other way round, which is what left the head adrift
    // in a field of nothing on a tall phone.
    expect(head.left, 30);
    expect(head.width, 393 - 60);
    expect(head.height, closeTo(head.width / (200 / 248), 0.5));
    // And 30 under it before the tiles start.
    expect(grid.top - head.bottom, closeTo(30, 0.5));
    expect(grid.height, greaterThan(HeadRegionGrid.reservedHeight));
  });

  testWidgets('the nose is its own area, and the cheek stops at it', (
    tester,
  ) async {
    await pumpPicker(tester);

    // One area, no L/R pair: it sits ON the midline rather than either side
    // of it. Owner reported the nose as unpickable — it was never dead, it
    // was filed as an eye or a cheek.
    await tester.tap(tile('Nose'));
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.nose]);

    // And the areas around it are cut to its outline, not run under it: the
    // tip of the nose is the nose, from either side of the face.
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

  testWidgets('the head is still tappable beside the tiles', (tester) async {
    await pumpPicker(tester);

    // The crown: the top of the drawing, which is the one band no other
    // area can be confused with on either view.
    final Rect head = tester.getRect(find.byType(HeadDiagram));
    await tester.tapAt(Offset(head.center.dx, head.top + head.height * 0.06));
    await tester.pump();

    expect(selected, <HeadRegion>[HeadRegion.crown]);
  });
}
