import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The app's only switch/toggle widget — every on/off toggle renders
/// through this so sizing stays consistent across the app (hard rule: no
/// raw [Switch] in feature or core code, only here).
///
/// [size] scales the whole control uniformly via [Transform.scale] (Material
/// doesn't expose a native size prop on [Switch]). Defaults to `1.0`
/// (native Material size, ~59x48 including default tap target).
///
/// Props are named to match [Switch] as closely as possible so existing
/// `Switch(...)` call sites can be swapped to `AppSwitcher(...)` with a
/// straight find-and-replace.
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({
    required this.value,
    required this.onChanged,
    this.size = 1.0,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Uniform scale factor applied to the whole switch. `1.0` = native
  /// Material size. E.g. `0.8` for a visibly smaller switch.
  final double size;

  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final ImageProvider? activeThumbImage;
  final ImageProvider? inactiveThumbImage;
  final WidgetStateProperty<Color?>? thumbColor;
  final WidgetStateProperty<Color?>? trackColor;
  final WidgetStateProperty<Color?>? trackOutlineColor;
  final WidgetStateProperty<Icon?>? thumbIcon;
  final MaterialTapTargetSize? materialTapTargetSize;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final switchWidget = Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
      activeThumbImage: activeThumbImage,
      inactiveThumbImage: inactiveThumbImage,
      thumbColor: thumbColor,
      trackColor: trackColor,
      trackOutlineColor: trackOutlineColor,
      thumbIcon: thumbIcon,
      materialTapTargetSize:
          materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
      dragStartBehavior: dragStartBehavior,
      mouseCursor: mouseCursor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
    );

    if (size == 1.0) return switchWidget;
    return Transform.scale(scale: size, child: switchWidget);
  }
}
