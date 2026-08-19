// Erase the Gemini watermark from a generated app-icon PNG.
//
//   dart run tool/strip_icon_marker.dart <in.png> <out.png> \
//     [--rect=x,y,w,h] [--from=dx,dy] [--feather=n]
//
// Gemini stamps two four-point sparkles into the bottom-right corner of every
// image it makes. They are not part of the artwork and must not ship, so this
// clone-stamps a clean patch of the same background over them: the pixels at
// `rect` are replaced by the pixels at `rect + from`, cross-faded over a
// `feather`-wide band so no seam appears.
//
// Why a clone and not a flat fill: the background is a gradient with faint
// diagonal streaks. A solid rectangle of #0C0C0E reads as a patch at 1024,
// which is exactly the size App Store Connect shows the marketing icon at.
//
// The defaults are tuned for the v2 artwork (1024x1024, sparkles inside
// x 866..1014 / y 864..1014, clean background 220px straight above). Pass the
// flags for any other image, and always eyeball the result at 1024 before
// running flutter_launcher_icons over it.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Region covering both sparkles, out to the two image edges.
const _defaultRect = [826, 824, 198, 200];

/// Offset to the patch that replaces it — straight up, clear of the head and
/// of the analysis panel.
const _defaultFrom = [0, -220];

/// Width of the cross-fade band, in pixels.
const _defaultFeather = 40;

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.length != 2) {
    stderr.writeln(
      'usage: dart run tool/strip_icon_marker.dart <in.png> <out.png> '
      '[--rect=x,y,w,h] [--from=dx,dy] [--feather=n]',
    );
    exit(64);
  }

  final rect = _ints(args, '--rect', _defaultRect, 4);
  final from = _ints(args, '--from', _defaultFrom, 2);
  final feather = _ints(args, '--feather', [_defaultFeather], 1).first;

  final input = File(positional[0]);
  if (!input.existsSync()) {
    stderr.writeln('no such file: ${input.path}');
    exit(66);
  }

  final image = decodePng(input.readAsBytesSync());
  if (image == null) {
    stderr.writeln('not a PNG: ${input.path}');
    exit(65);
  }
  stdout.writeln('in       ${input.path} ${image.width}x${image.height}');

  final x0 = rect[0];
  final y0 = rect[1];
  final x1 = x0 + rect[2]; // exclusive
  final y1 = y0 + rect[3];
  final dx = from[0];
  final dy = from[1];

  // Only fade on the sides that have image beyond them. A side sitting on the
  // image border has nothing to fade into, and fading there would leave the
  // watermark half-visible in the corner.
  final fadeLeft = x0 > 0;
  final fadeTop = y0 > 0;
  final fadeRight = x1 < image.width;
  final fadeBottom = y1 < image.height;

  if (x0 + dx < 0 ||
      y0 + dy < 0 ||
      x1 + dx > image.width ||
      y1 + dy > image.height) {
    stderr.writeln('source patch falls outside the image');
    exit(65);
  }

  // Level-match the patch on the fade band, where both regions describe the
  // same background: the corner is darker than the pixels 220 up, and copying
  // them across untouched would show as a bright block.
  var bandCount = 0;
  var dr = 0.0, dg = 0.0, db = 0.0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final w = _weight(
        x, y, x0, y0, x1, y1, feather, fadeLeft, fadeTop, fadeRight, fadeBottom,
      );
      if (w <= 0 || w >= 1) continue;
      final dst = image.getPixel(x, y);
      final src = image.getPixel(x + dx, y + dy);
      dr += dst.r - src.r;
      dg += dst.g - src.g;
      db += dst.b - src.b;
      bandCount++;
    }
  }
  if (bandCount > 0) {
    dr /= bandCount;
    dg /= bandCount;
    db /= bandCount;
  }
  stdout.writeln(
    'match    ${dr.toStringAsFixed(2)}, ${dg.toStringAsFixed(2)}, '
    '${db.toStringAsFixed(2)} over $bandCount px',
  );

  // Read the whole patch before writing, so a patch that overlaps the region
  // cannot feed already-rewritten pixels back into itself.
  final source = copyCrop(
    image,
    x: x0 + dx,
    y: y0 + dy,
    width: x1 - x0,
    height: y1 - y0,
  );

  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final w = _weight(
        x, y, x0, y0, x1, y1, feather, fadeLeft, fadeTop, fadeRight, fadeBottom,
      );
      if (w <= 0) continue;
      final dst = image.getPixel(x, y);
      final src = source.getPixel(x - x0, y - y0);
      image.setPixelRgba(
        x,
        y,
        _mix(dst.r, src.r + dr, w),
        _mix(dst.g, src.g + dg, w),
        _mix(dst.b, src.b + db, w),
        _mix(dst.a, src.a, w),
      );
    }
  }

  final output = File(positional[1]);
  output.writeAsBytesSync(encodePng(image));
  stdout.writeln('out      ${output.path}');
}

/// Cross-fade weight of the patch at ([x], [y]): 1 in the core, 0 at a faded
/// edge, smoothstepped in between.
double _weight(
  int x,
  int y,
  int x0,
  int y0,
  int x1,
  int y1,
  int feather,
  bool fadeLeft,
  bool fadeTop,
  bool fadeRight,
  bool fadeBottom,
) {
  var w = 1.0;
  if (fadeLeft) w = math.min(w, _smoothstep((x - x0 + 0.5) / feather));
  if (fadeRight) w = math.min(w, _smoothstep((x1 - x - 0.5) / feather));
  if (fadeTop) w = math.min(w, _smoothstep((y - y0 + 0.5) / feather));
  if (fadeBottom) w = math.min(w, _smoothstep((y1 - y - 0.5) / feather));
  return w;
}

double _smoothstep(double t) {
  final c = t.clamp(0.0, 1.0);
  return c * c * (3 - 2 * c);
}

num _mix(num dst, num src, double w) =>
    (dst * (1 - w) + src * w).round().clamp(0, 255);

List<int> _ints(List<String> args, String flag, List<int> fallback, int count) {
  final arg = args.firstWhere(
    (a) => a.startsWith('$flag='),
    orElse: () => '',
  );
  if (arg.isEmpty) return fallback;
  final parts = arg.substring(flag.length + 1).split(',');
  if (parts.length != count) {
    stderr.writeln('$flag wants $count comma-separated integers');
    exit(64);
  }
  return parts.map((p) => int.parse(p.trim())).toList();
}
