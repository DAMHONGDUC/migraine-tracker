import 'dart:ui';

import '../../domain/enums/head_region.dart';

/// The one owner of where every [HeadRegion] is on the drawing.
///
/// Everything here is in **design units** — a [designSize] box that
/// `head_front.svg` and `head_back.svg` share as their viewBox. Nothing is
/// ever scaled here: the painter scales its canvas instead, and [hitTest]
/// divides the tap back down. One scale in one direction each way beats a
/// transform on every path, and it keeps every number in this file readable
/// against the SVGs beside it. The two SVGs carry only line art: the
/// silhouette, the ears, the neck and (front only) the face. Every filled
/// area and every divider between areas is drawn from this file, so the
/// region a tap lands in and the region that lights up can never drift
/// apart.
///
/// **A pickable area follows the artwork exactly** (owner's rule, see the
/// feature's `CLAUDE.md`). That is why the cuts down the head are curves
/// rather than the straight rules they used to be: the drawing's brow,
/// cheek and jaw lines bow with the face, so a band that cut straight across
/// them would fill a strip the user can see is not the strip they tapped.
/// [_cut] is the single curve every band, every divider and every hit test
/// is built from, so all three bow together by construction.
///
/// The head and the neck are the two shapes that live in both places —
/// traced here for clipping and hit-testing, stroked there for the visible
/// outline. Edit one and you must edit the other two.
final class HeadRegionGeometry {
  const HeadRegionGeometry._();

  /// The SVG viewBox, and the aspect ratio the widget locks itself to.
  ///
  /// **Only as tall as the drawing needs.** The diagram is height bound
  /// wherever it is used — an `Expanded` in the log step, a fixed row on the
  /// detail screen — so its width comes out of this ratio and every empty
  /// row in the box is size the head does not get. The neck runs off the
  /// bottom edge rather than ending inside it for the same reason.
  static const Size designSize = Size(200, 248);

  static double get aspectRatio => designSize.width / designSize.height;

  // Horizontal cuts down the head. Named for what a user would call them,
  // not for the anatomy, since they are also where the divider lines land.
  static const double _hairline = 62;
  static const double _brow = 102;
  static const double _underEye = 144;
  static const double _mouth = 184;
  static const double _chin = 231;

  /// Where the back view splits the back of the head from the nape — below
  /// the ears, which is the only landmark that view has. The front's own
  /// cuts are useless here: there is no brow and no mouth to line up with.
  static const double _backNeck = 160;

  // Vertical cuts. [_centre] splits every band into a left and a right; the
  // other two only cut the eye band, so a temple is its own area.
  static const double _centre = 100;
  static const double _templeEdgeL = 46;
  static const double _templeEdgeR = 154;

  /// How far the ends of a horizontal cut hang below its middle. Matched to
  /// the drawing: the face is a curved surface, and a line across it rises
  /// in the centre.
  static const double _sag = 5;

  /// One band of the drawing, as (top cut, bottom cut, left edge, right
  /// edge). Clipped to the silhouette on the way out, so four numbers are
  /// enough to describe a shape that ends up curved on every side.
  ///
  /// [HeadRegion.crown] gets the same band on both views on purpose — the
  /// top of the head is one place however you look at it. Its top is the top
  /// of the box rather than a cut, and [HeadRegion.nape]'s bottom is the
  /// bottom of the box, because both run off the drawing rather than meeting
  /// another area.
  static const Map<HeadRegion, _Band> _bands = <HeadRegion, _Band>{
    HeadRegion.crown: _Band(0, _hairline, 0, 200, topSag: 0),
    HeadRegion.foreheadL: _Band(_hairline, _brow, 0, _centre),
    HeadRegion.foreheadR: _Band(_hairline, _brow, _centre, 200),
    HeadRegion.templeL: _Band(_brow, _underEye, 0, _templeEdgeL),
    HeadRegion.eyeL: _Band(_brow, _underEye, _templeEdgeL, _centre),
    HeadRegion.eyeR: _Band(_brow, _underEye, _centre, _templeEdgeR),
    HeadRegion.templeR: _Band(_brow, _underEye, _templeEdgeR, 200),
    HeadRegion.cheekL: _Band(_underEye, _mouth, 0, _centre),
    HeadRegion.cheekR: _Band(_underEye, _mouth, _centre, 200),
    HeadRegion.jawL: _Band(_mouth, _chin, 0, _centre),
    HeadRegion.jawR: _Band(_mouth, _chin, _centre, 200),
    HeadRegion.occipitalL: _Band(_hairline, _backNeck, 0, _centre),
    HeadRegion.occipitalR: _Band(_hairline, _backNeck, _centre, 200),
    HeadRegion.nape: _Band(_backNeck, 248, 0, 200, bottomSag: 0),
  };

  /// The head, ears excluded — the same curve both SVGs stroke.
  static Path _headPath() => Path()
    ..moveTo(100, 8)
    ..cubicTo(148, 8, 181, 42, 183, 98)
    ..cubicTo(184, 120, 180, 142, 173, 162)
    ..cubicTo(164, 186, 148, 208, 130, 221)
    ..cubicTo(120, 228, 110, 231, 100, 231)
    ..cubicTo(90, 231, 80, 228, 70, 221)
    ..cubicTo(52, 208, 36, 186, 27, 162)
    ..cubicTo(20, 142, 16, 120, 17, 98)
    ..cubicTo(19, 42, 52, 8, 100, 8)
    ..close();

  /// The neck, from where it leaves the jaw down to the bottom of the box —
  /// the same two curves the SVGs stroke, closed across the top and the
  /// bottom so it can be filled. The top edge runs between the two points
  /// where those curves meet the head, so the union of the two shapes has no
  /// notch where they join.
  static Path _neckPath() => Path()
    ..moveTo(146, 206)
    ..cubicTo(137, 222, 141, 236, 155, 248)
    ..lineTo(45, 248)
    ..cubicTo(59, 236, 63, 222, 54, 206)
    ..close();

  /// What a region is clipped to, and what the painter tints as the body.
  ///
  /// The neck belongs to the back view alone: [HeadRegion.nape] is the only
  /// area drawn over it, so on the front it is line art the user cannot tap
  /// and must not see filled either.
  static Path outline(HeadView view) => switch (view) {
    HeadView.front => _headPath(),
    HeadView.back => Path.combine(
      PathOperation.union,
      _headPath(),
      _neckPath(),
    ),
  };

  /// The nose, as its own closed shape rather than a slab of a band.
  ///
  /// **It is the one region whose edge is a drawing, not a cut**, which is
  /// also why the SVGs no longer stroke a nose in line-art white: the shape
  /// below IS the nose the user sees, drawn by `HeadRegionPainter` in the
  /// same colour as every other divider, so the boundary they tap and the
  /// boundary they see are one line. The SVG keeps only a couple of thin
  /// strokes inside it — nostrils, no outline (owner's rule).
  ///
  /// It starts just under [_brow] and ends above [_mouth], so it never
  /// reaches a cut and never has to be clipped to one.
  static Path nosePath() => Path()
    ..moveTo(96, 104)
    ..cubicTo(94, 124, 88, 142, 83, 154)
    ..cubicTo(79, 166, 88, 174, 100, 174)
    ..cubicTo(112, 174, 121, 166, 117, 154)
    ..cubicTo(112, 142, 106, 124, 104, 104)
    ..close();

  /// One region's fillable shape, or null when [region] is not drawn on
  /// [view].
  ///
  /// Every band that the nose reaches into gets it subtracted, so the four
  /// areas around it stop at its outline instead of running under it — the
  /// difference between a nose you can tap and a nose that is a picture of
  /// somebody's cheek.
  static Path? regionPath(HeadRegion region, HeadView view) {
    if (!region.showsOn(view)) return null;

    if (region == HeadRegion.nose) return nosePath();

    final Path band = Path.combine(
      PathOperation.intersect,
      outline(view),
      _bands[region]!.path(),
    );

    return _touchesNose.contains(region)
        ? Path.combine(PathOperation.difference, band, nosePath())
        : band;
  }

  /// The four the nose is cut out of. Named rather than computed: intersect
  /// tests on every region on every paint is work to save four constants.
  static const Set<HeadRegion> _touchesNose = <HeadRegion>{
    HeadRegion.eyeL,
    HeadRegion.eyeR,
    HeadRegion.cheekL,
    HeadRegion.cheekR,
  };

  /// The region a tap fell in, or null when it missed the head. [local] is
  /// in widget coordinates and [size] the widget's own, so the tap comes
  /// back down to design units here rather than every path going up.
  ///
  /// Walks [HeadRegion.of] rather than the band map so the answer follows the
  /// view: the same point is a cheek from the front and the back of the head
  /// from behind.
  static HeadRegion? hitTest(Offset local, HeadView view, Size size) {
    if (size.isEmpty) return null;

    final Offset point = Offset(
      local.dx * designSize.width / size.width,
      local.dy * designSize.height / size.height,
    );

    for (final HeadRegion region in HeadRegion.of(view)) {
      final Path? path = regionPath(region, view);
      if (path != null && path.contains(point)) return region;
    }

    return null;
  }

  /// The lines between regions, as one path to stroke. Drawn from the same
  /// [_cut] the bands are built from, so a line can never sit somewhere a
  /// tap does not also divide — and never runs past the last area it
  /// separates, which is why the centre line stops at the chin on the front
  /// and at the nape's own cut on the back.
  ///
  /// The centre line and the under-eye cut both run straight at the nose;
  /// neither is shortened here. `HeadRegionPainter` clips this whole path to
  /// the face MINUS [nosePath], which erases exactly the stretches that
  /// would have crossed a single area, and keeps this method free of the
  /// nose entirely.
  static Path dividers(HeadView view) {
    final Path path = Path();

    void horizontal(double y) {
      final _Arc arc = _cut(y, _sag, 0, 200);
      path
        ..moveTo(arc.start.dx, arc.start.dy)
        ..quadraticBezierTo(
          arc.control.dx,
          arc.control.dy,
          arc.end.dx,
          arc.end.dy,
        );
    }

    void vertical(double x, double top, double bottom) => path
      ..moveTo(x, _cut(top, _sag, 0, x).end.dy)
      ..lineTo(x, _cut(bottom, _sag, 0, x).end.dy);

    switch (view) {
      case HeadView.front:
        horizontal(_hairline);
        horizontal(_brow);
        horizontal(_underEye);
        horizontal(_mouth);
        vertical(_centre, _hairline, _chin);
        vertical(_templeEdgeL, _brow, _underEye);
        vertical(_templeEdgeR, _brow, _underEye);
      case HeadView.back:
        horizontal(_hairline);
        horizontal(_backNeck);
        vertical(_centre, _hairline, _backNeck);
    }

    return path;
  }

  /// The stretch of the cut at [y] between [xFrom] and [xTo], as its own
  /// quadratic.
  ///
  /// The full cut is the quadratic through `(0, y + sag)`, `(100, y - sag)`
  /// and `(200, y + sag)`. Its x moves linearly with t — the three control
  /// x's are evenly spaced — so `t = x / 200` exactly, and the sub-curve
  /// falls out of the blossom without a search. That is what lets a band
  /// stop at the temple edge on the *same* curve its neighbour continues
  /// on: two bands meeting at x = 50 share a point, not an approximation of
  /// one.
  static _Arc _cut(double y, double sag, double xFrom, double xTo) {
    final double t0 = xFrom / 200;
    final double t1 = xTo / 200;
    final double end = y + sag;
    final double middle = y - sag;

    double blossom(double a, double b) =>
        (1 - a) * (1 - b) * end +
        ((1 - a) * b + (1 - b) * a) * middle +
        a * b * end;

    return _Arc(
      Offset(xFrom, blossom(t0, t0)),
      Offset((xFrom + xTo) / 2, blossom(t0, t1)),
      Offset(xTo, blossom(t1, t1)),
    );
  }
}

/// A stretch of one horizontal cut: start, quadratic control, end.
final class _Arc {
  const _Arc(this.start, this.control, this.end);

  final Offset start;
  final Offset control;
  final Offset end;
}

/// One area before it is clipped — two cuts and the two vertical edges
/// between them.
final class _Band {
  const _Band(
    this.top,
    this.bottom,
    this.left,
    this.right, {
    this.topSag = HeadRegionGeometry._sag,
    this.bottomSag = HeadRegionGeometry._sag,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;

  /// Zero where the edge is the edge of the box rather than a cut against
  /// another area — the crown's top and the nape's bottom.
  final double topSag;
  final double bottomSag;

  Path path() {
    final _Arc above = HeadRegionGeometry._cut(top, topSag, left, right);
    // Right to left, so the two arcs close into a ring without a crossing.
    final _Arc below = HeadRegionGeometry._cut(bottom, bottomSag, right, left);

    return Path()
      ..moveTo(above.start.dx, above.start.dy)
      ..quadraticBezierTo(
        above.control.dx,
        above.control.dy,
        above.end.dx,
        above.end.dy,
      )
      ..lineTo(below.start.dx, below.start.dy)
      ..quadraticBezierTo(
        below.control.dx,
        below.control.dy,
        below.end.dx,
        below.end.dy,
      )
      ..close();
  }
}
