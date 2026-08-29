import 'dart:ui';

import '../../domain/enums/head_region.dart';

/// The one owner of where every [HeadRegion] is on the drawing.
final class HeadRegionGeometry {
  const HeadRegionGeometry._();

  /// The SVG viewBox, and the aspect ratio the widget locks itself to.
  static const Size designSize = Size(200, 248);

  static double get aspectRatio => designSize.width / designSize.height;

  // Horizontal cuts down the head. Named for what a user would call them, not for the anatomy, since they are also where the divider lines land.
  static const double _hairline = 62;
  static const double _brow = 102;
  static const double _underEye = 144;
  static const double _mouth = 184;
  static const double _chin = 231;

  /// Where the back view splits the back of the head from the nape — below the ears, which is the only landmark that view has.
  static const double _backNeck = 160;

  // Vertical cuts. [_centre] splits every band into a left and a right; the other two only cut the eye band, so a temple is its own area.
  static const double _centre = 100;
  static const double _templeEdgeL = 46;
  static const double _templeEdgeR = 154;

  /// How far the ends of a horizontal cut hang below its middle.
  static const double _sag = 5;

  /// One band of the drawing, as (top cut, bottom cut, left edge, right edge).
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

  /// The neck, from where it leaves the jaw down to the bottom of the box — the same two curves the SVGs stroke, closed across the top and the bottom so.
  static Path _neckPath() => Path()
    ..moveTo(146, 206)
    ..cubicTo(137, 222, 141, 236, 155, 248)
    ..lineTo(45, 248)
    ..cubicTo(59, 236, 63, 222, 54, 206)
    ..close();

  /// What a region is clipped to, and what the painter tints as the body.
  static Path outline(HeadView view) => switch (view) {
    HeadView.front => _headPath(),
    HeadView.back => Path.combine(
      PathOperation.union,
      _headPath(),
      _neckPath(),
    ),
  };

  /// The nose, as its own closed shape rather than a slab of a band.
  static Path nosePath() => Path()
    ..moveTo(96, 104)
    ..cubicTo(94, 124, 88, 142, 83, 154)
    ..cubicTo(79, 166, 88, 174, 100, 174)
    ..cubicTo(112, 174, 121, 166, 117, 154)
    ..cubicTo(112, 142, 106, 124, 104, 104)
    ..close();

  /// One region's fillable shape, or null when [region] is not drawn on [view].
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

  /// The four the nose is cut out of. Named rather than computed: intersect tests on every region on every paint is work to save four constants.
  static const Set<HeadRegion> _touchesNose = <HeadRegion>{
    HeadRegion.eyeL,
    HeadRegion.eyeR,
    HeadRegion.cheekL,
    HeadRegion.cheekR,
  };

  /// The region a tap fell in, or null when it missed the head.
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

  /// The lines between regions, as one path to stroke.
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

  /// The stretch of the cut at [y] between [xFrom] and [xTo], as its own quadratic.
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

/// One area before it is clipped — two cuts and the two vertical edges between them.
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

  /// Zero where the edge is the edge of the box rather than a cut against another area — the crown's top and the nape's bottom.
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
