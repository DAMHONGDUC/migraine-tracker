import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import 'head_viewport.dart';

/// The GPU-independent gesture boundary is testable with the same recognizers the scene uses.
class HeadGestureSurface extends StatefulWidget {
  const HeadGestureSurface({
    required this.pose,
    required this.child,
    this.onChanged,
    this.onStart,
    this.onTap,
    super.key,
  });

  final HeadViewport pose;
  final Widget child;
  final ValueChanged<HeadViewport>? onChanged;
  final VoidCallback? onStart;
  final ValueChanged<Offset>? onTap;

  @override
  State<HeadGestureSurface> createState() => _HeadGestureSurfaceState();
}

class _HeadGestureSurfaceState extends State<HeadGestureSurface> {
  final Set<int> _pointers = <int>{};
  bool _moved = false;
  bool _multitouch = false;
  double _zoom = 1;
  double _scale = 1;
  int _scalePointers = 0;
  Offset? _down;
  late HeadViewport _gesturePose;

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) {
      _moved = false;
      _multitouch = false;
      _down = event.localPosition;
      widget.onStart?.call();
    }
    _pointers.add(event.pointer);
    if (_pointers.length > 1) _multitouch = true;
  }

  void _start(ScaleStartDetails details) {
    _gesturePose = widget.pose;
    _zoom = widget.pose.zoom;
    _scale = 1;
    _scalePointers = details.pointerCount;
    SdLogger.action(
      LogTagConstant.attackLog,
      'Head gesture started',
      <String, Object?>{'pointers': details.pointerCount},
    );
  }

  void _update(ScaleUpdateDetails details) {
    // Pointer updates can arrive before the parent rebuilds with the last pose.
    final HeadViewport pose = _gesturePose;
    final bool pinch = details.pointerCount > 1;

    if (_scalePointers != details.pointerCount) {
      _zoom = pose.zoom;
      _scale = details.scale;
      _scalePointers = details.pointerCount;
    }
    if (pinch) _multitouch = true;
    if (details.focalPointDelta != Offset.zero || details.scale != _scale) {
      _moved = true;
    }
    _gesturePose = HeadViewportUtils.constrained((
      yaw: pinch
          ? pose.yaw
          : pose.yaw -
                details.focalPointDelta.dx * HeadViewportUtils.degreesPerPoint,
      pitch: pinch
          ? pose.pitch
          : pose.pitch +
                details.focalPointDelta.dy * HeadViewportUtils.degreesPerPoint,
      zoom: pinch ? _zoom * details.scale / _scale : pose.zoom,
    ));
    widget.onChanged?.call(_gesturePose);
  }

  void _tap(TapUpDetails details) {
    if (_moved || _multitouch) return;
    widget.onTap?.call(details.localPosition);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _pointerDown,
    onPointerMove: (PointerMoveEvent event) {
      if (_down != null &&
          (event.localPosition - _down!).distance > kTouchSlop) {
        _moved = true;
      }
    },
    onPointerUp: (PointerUpEvent event) => _pointers.remove(event.pointer),
    onPointerCancel: (PointerCancelEvent event) {
      _pointers.remove(event.pointer);
      _moved = true;
    },
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTap == null ? null : _tap,
      onScaleStart: widget.onChanged == null ? null : _start,
      onScaleUpdate: widget.onChanged == null ? null : _update,
      onScaleEnd: widget.onChanged == null
          ? null
          : (ScaleEndDetails details) => SdLogger.info(
              LogTagConstant.attackLog,
              'Head gesture finished',
              <String, Object?>{
                'yaw': _gesturePose.yaw,
                'pitch': _gesturePose.pitch,
                'zoom': _gesturePose.zoom,
              },
            ),
      child: widget.child,
    ),
  );
}
