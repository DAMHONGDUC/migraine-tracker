import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/head_region.dart';
import '../../domain/enums/head_rotation_speed.dart';
import '../../providers.dart';
import '../controllers/head_controls_controller.dart';
import 'head_diagram.dart';
import 'head_pose.dart';
import 'head_region_geometry.dart';
import 'head_region_grid.dart';
import 'head_scene_store.dart';
import 'head_viewport.dart';

part 'head_region_picker_controls.dart';

/// Picking where it hurts: a Front/Back tab pair, the head itself, and the
/// same areas as named tiles under it.
///
/// **The head and the tiles are one answer with two doors.** Both call
/// [_toggle], so a band and its tile light up together whichever was
/// touched; the tiles are there because the bands carry no labels and the
/// small ones are hard to hit, not because they record anything the head
/// cannot.
///
/// Shared by the log flow's second tap ([LocationStep]) and the attack
/// detail's edit sheet, so correcting a location afterwards looks exactly
/// like picking it in the first place.
///
/// **The head never moves, and it gets every point nothing else needs.** It
/// is the one thing on this screen the user is aiming at, and it sits in an
/// `Expanded`, so anything under it that changes size hands the difference
/// straight to the diagram and redraws it somewhere else — which is why
/// [HeadRegionGrid] reserves a constant height for the roomiest view. It is
/// also why there is no line spelling the picked areas out under the grid
/// any more: the tiles name every one of them and light the picked ones up,
/// so that line cost the head 40pt to repeat what was already on screen.
///
/// **The tab is view state, not an answer** — it lives here rather than in
/// `LogController`, because turning the head around records nothing. Only
/// [onChanged] does. It opens on whichever side already holds more of
/// [selected], so editing a back-of-head attack does not open on a blank
/// face.
///
/// **The turn is what the tabs do now.** They used to cross-fade between two
/// flat drawings; they animate a half turn of one solid, which is the thing
/// the flat pair could never say — that the face and the nape are two sides of
/// the same head. A drag turns it freely, and the tabs stay because they carry
/// the per-side count and are the way in for anyone who does not drag.
class HeadRegionPicker extends ConsumerStatefulWidget {
  const HeadRegionPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<HeadRegion> selected;
  final ValueChanged<List<HeadRegion>> onChanged;

  /// The height of the row the Front/Back tabs and the camera controls share.
  ///
  /// Fixed rather than intrinsic, because the head's box is worked out from
  /// what this row leaves and an intrinsic height is only known once the row
  /// has already been laid out. It is the taller of the two things in it and
  /// it does not change when the controls come and go — a head that resized
  /// the moment the model finished loading would redraw itself under the
  /// user's thumb.
  ///
  /// Public because `head_region_picker_test.dart` measures the air above the
  /// head from this row, and the tabs' own pill is 2pt shorter and centred in
  /// it — measuring off the pill reads that 1pt as the ring going uneven.
  static double get topRowHeight =>
      math.max(SdSegmentedTabsV2.height, _HeadZoomControls.height);

  @override
  ConsumerState<HeadRegionPicker> createState() => _HeadRegionPickerState();
}

class _HeadRegionPickerState extends ConsumerState<HeadRegionPicker>
    with SingleTickerProviderStateMixin {
  /// The live angle. The tabs animate it and a drag sets it; nothing else may.
  double _pitch = 0;
  bool _available = HeadSceneStore.template != null;

  /// Zoom and rotation speed are the user's own settings and outlive the
  /// screen, so they live in [HeadControlsController] rather than here — the
  /// angle does not (see that controller).
  HeadControls get _controls => ref.read(headControlsProvider);

  /// The level the user set, or — while they have not set one — the level that
  /// fills the viewport the head is drawn in.
  double get _zoom => _controls.zoom ?? _fit;

  /// What [HeadViewportUtils.fitZoom] answered for the box the layout last
  /// handed the head.
  ///
  /// Assigned from inside `build`, which is where the box's size is known, and
  /// the same way `HeadScene` keeps the viewport it renders at. Read after the
  /// fact by Reset and by the +/- buttons, which have no constraints of their
  /// own to ask.
  double _fit = HeadViewportUtils.minZoom;

  late double _yaw = HeadPose.yawFor(HeadRegion.primaryView(widget.selected));

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: _turnDuration,
  )..addListener(_onTurn);

  Animation<double>? _turning;

  /// Long enough to read as one object turning rather than as a cut, short
  /// enough not to be a wait. Calm curve, no overshoot (hard rule 3).
  static const Duration _turnDuration = Duration(milliseconds: 380);

  /// Which side is facing, derived rather than stored — a second copy of the
  /// angle is a second thing that can disagree with it.
  HeadView get _view => HeadPose.viewAt(_yaw);

  /// How far the head sits in from everything around it — the screen edge
  /// either side, the tabs above, the tiles below. Owner's number, and the
  /// same on both axes on purpose: the head is a round thing in a column of
  /// rectangles, and an even ring of air is what stops it reading as wedged
  /// between them. Still wider than the step's own 16pt gutter, which the
  /// tabs and the tiles keep, because those two want the width and the head
  /// does not — but only just: this number is also what caps the head's
  /// size, since the head is sized from the width inside it.
  static double get _headInset => SdSpacingConstant.w24;

  /// Toggles one area, keeping the result in [HeadRegion] order so two
  /// attacks naming the same areas are the same list — the sync codec
  /// compares payloads, and an order that followed the taps would make an
  /// unchanged attack look edited.
  void _toggle(HeadRegion region) {
    final Set<HeadRegion> next = widget.selected.toSet();

    SdLogger.action(
      LogTagConstant.attackLog,
      'Toggle head region',
      <String, Object?>{'selectedCount': next.length},
    );

    if (!next.remove(region)) next.add(region);

    widget.onChanged(<HeadRegion>[
      for (final HeadRegion candidate in HeadRegion.values)
        if (next.contains(candidate)) candidate,
    ]);
    SdLogger.info(
      LogTagConstant.attackLog,
      'Head selection updated',
      <String, Object?>{'selectedCount': next.length},
    );
  }

  void _onTurn() {
    final Animation<double>? turning = _turning;

    if (turning == null) return;

    setState(() => _yaw = turning.value);
  }

  /// Turns to face [view] the short way round, so the head never spins most of
  /// a circle to travel a few degrees.
  void _snapTo(HeadView view) {
    SdLogger.action(
      LogTagConstant.attackLog,
      'Snap head view',
      <String, Object?>{'view': view.name},
    );
    _turn.stop();
    _pitch = 0;
    if (MediaQuery.disableAnimationsOf(context) || !_available) {
      setState(() => _yaw = HeadPose.yawFor(view));
      SdLogger.info(
        LogTagConstant.attackLog,
        'Head view snapped',
        <String, Object?>{'yaw': _yaw},
      );
      return;
    }
    _turning = Tween<double>(
      begin: _yaw,
      end: HeadPose.shortestTurn(_yaw, HeadPose.yawFor(view)),
    ).animate(CurvedAnimation(parent: _turn, curve: Curves.easeInOutCubic));

    _turn.forward(from: 0);
    SdLogger.info(
      LogTagConstant.attackLog,
      'Head turn scheduled',
      <String, Object?>{'yaw': HeadPose.yawFor(view)},
    );
  }

  /// A drag owns the angle outright: an animation still running under it would
  /// pull the head out from under the finger.
  void _dragTo(double yaw) {
    if (_turn.isAnimating) _turn.stop();

    setState(() => _yaw = yaw);
  }

  void _poseTo(HeadViewport pose) {
    _turn.stop();
    setState(() {
      _yaw = pose.yaw;
      _pitch = pose.pitch;
    });
    // On screen this frame, in the Keychain once the fingers stop: the
    // controller debounces the write, which is what makes a pinch — a new
    // zoom per pointer frame — one save rather than fifty.
    ref.read(headControlsProvider.notifier).setZoom(pose.zoom);
  }

  void _setZoom(double zoom) {
    final HeadViewport pose = HeadViewportUtils.constrained((
      yaw: _yaw,
      pitch: _pitch,
      zoom: zoom,
    ));

    SdLogger.action(
      LogTagConstant.attackLog,
      'Set head zoom',
      <String, Object?>{'zoom': pose.zoom},
    );
    _poseTo(pose);
    SdLogger.info(LogTagConstant.attackLog, 'Head zoom set', <String, Object?>{
      'zoom': _zoom,
    });
  }

  void _reduceRotationSpeed() =>
      ref.read(headControlsProvider.notifier).reduceRotationSpeed();

  /// Face on, level, and back to whatever fills this screen.
  ///
  /// It FORGETS the user's level rather than setting one, which is the
  /// difference between Reset and a zoom button: going back to a number would
  /// pin the head to a size chosen for some other screen, and the size this
  /// one can hold is the thing Reset is for.
  void _resetView() {
    SdLogger.action(
      LogTagConstant.attackLog,
      'Reset head view',
      <String, Object?>{'view': _view.name},
    );
    ref.read(headControlsProvider.notifier).clearZoom();
    _turn.stop();
    setState(() {
      _yaw = HeadPose.yawFor(_view);
      _pitch = 0;
    });
    SdLogger.info(
      LogTagConstant.attackLog,
      'Head view reset',
      <String, Object?>{'yaw': _yaw, 'zoom': _zoom},
    );
  }

  void _availabilityChanged(bool available) {
    if (_available != available) setState(() => _available = available);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  int _countOn(HeadView view) =>
      widget.selected.where((HeadRegion r) => r.showsOn(view)).length;

  /// Null rather than 0: a bare tab reads as "nothing here yet", where a
  /// zero reads as a number the user has to check.
  int? _badgeFor(HeadView view) {
    final int count = _countOn(view);

    return count == 0 ? null : count;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final HeadControls controls = ref.watch(headControlsProvider);

    // ONE LayoutBuilder over the whole picker, not one over the head alone.
    // The controls sit in the top row now, and the level they read out is
    // measured off the head's box — so the box has to be worked out before the
    // row is built, and a builder nested under the row is one frame too late.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = _headInset;
        // What is left once the top row has taken its fixed slice.
        final double body = constraints.maxHeight - HeadRegionPicker.topRowHeight;
        // The head is sized from its WIDTH, not from what is left over
        // (owner's rule); the `min` only guards a short column. What it does
        // not use goes to the tiles, and the rest is air around the head.
        final double byWidth =
            (constraints.maxWidth - _headInset * 2) /
            HeadRegionGeometry.aspectRatio;
        final double head = math.min(
          byWidth,
          body - gap - HeadRegionGrid.reservedHeight,
        );
        final double grid = (body - head - gap).clamp(
          HeadRegionGrid.reservedHeight,
          HeadRegionGrid.maxHeight,
        );
        // The scene gets the full width and `head` of height, and the level
        // that fills THAT is a different number on a phone and on an iPad.
        // The model's own bounds, not a stand-in — the fit is the head's
        // corners against the frame's edges.
        final vm.Aabb3? bounds = HeadSceneStore.template?.combinedWorldBounds;

        _fit = bounds == null
            ? HeadViewportUtils.minZoom
            : HeadViewportUtils.fitZoom(
                bounds,
                Size(constraints.maxWidth, head),
              );

        final double zoom = controls.zoom ?? _fit;

        return Column(
          children: <Widget>[
            // **The tabs and the camera controls share one row** (owner's
            // rule, 2026-09-21). The controls used to float over the head, and
            // that was fine while the head was framed with air above the
            // crown — once it opens filling its box, the same overlay covers
            // the crown, which is a region the user has to be able to tap. So
            // the tabs give up the width they were not using and the controls
            // move up into it, and the head gets its whole box back with
            // nothing on top of it.
            SizedBox(
              height: HeadRegionPicker.topRowHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                ),
                child: Row(
                  children: <Widget>[
                    // Whatever the controls leave. Two words and a count do
                    // not need half a phone, and the segment labels ellipsize
                    // where a locale spells them longer.
                    Expanded(
                      child: SdSegmentedTabsV2(
                        segments: <SdSegmentV2>[
                          SdSegmentV2(
                            label: l10n.logLocationViewFront,
                            count: _badgeFor(HeadView.front),
                          ),
                          SdSegmentV2(
                            label: l10n.logLocationViewBack,
                            count: _badgeFor(HeadView.back),
                          ),
                        ],
                        selectedIndex: HeadView.values.indexOf(_view),
                        onSelected: (int index) =>
                            _snapTo(HeadView.values[index]),
                      ),
                    ),
                    // Nothing to aim a camera at without a model, so the row
                    // is the tabs alone — and it keeps its height either way,
                    // so the head does not resize when the model arrives.
                    if (_available) ...<Widget>[
                      SizedBox(width: SdSpacingConstant.w8),
                      _HeadZoomControls(
                        zoom: zoom,
                        rotationSpeed: controls.rotationSpeed,
                        onZoom: _setZoom,
                        onReduceRotationSpeed: _reduceRotationSpeed,
                        onReset: _resetView,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                child: SizedBox(
                  height: head,
                  width: double.infinity,
                  child: Semantics(
                    label: widget.selected.isEmpty
                        ? l10n.logLocationNone
                        : widget.selected.label(l10n),
                    excludeSemantics: true,
                    child: _SideLabelled(
                      inset: _headInset,
                      overlay: _available,
                      leftOnLeft:
                          !_available || HeadPose.leftIsOnScreenLeft(_yaw),
                      child: HeadDiagram(
                        expandScene: true,
                        selected: widget.selected,
                        view: _view,
                        yaw: _yaw,
                        pitch: _pitch,
                        zoom: zoom,
                        onPoseChanged: _poseTo,
                        onInteractionStart: _turn.stop,
                        onAvailabilityChanged: _availabilityChanged,
                        onRegionTapped: _toggle,
                        onYawChanged: _dragTo,
                        rotationSpeed: controls.rotationSpeed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: grid,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                ),
                child: HeadRegionGrid(
                  view: _view,
                  selected: widget.selected,
                  onToggle: _toggle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The L and R that flank the head. They are the whole reason the front view
/// is drawn mirrored: without them nobody can tell whose left is meant, and
/// with them the answer has to be "yours" on both views (see [HeadRegion]).
///
/// In 3D they overlay the full-width viewport. The flat fallback keeps its
/// inset and aspect ratio so its artwork and hit targets stay aligned.
///
/// **They swap sides when the head turns past its silhouette** ([leftOnLeft]).
/// Two flat drawings could keep the user's left on the screen's left on both
/// views — the front one was mirrored for exactly that. One solid cannot, and
/// a label that is silently wrong is worse than one that moves. The swap is a
/// cut rather than a fade: it happens at the quarter turn, where the side it
/// names is edge-on and nobody is reading it.
///
/// [child] stays a NON-positioned stack child so it keeps its own aspect
/// ratio and the stack takes its size. `Positioned.fill` would force the
/// box's ratio onto a 200x248 drawing and squash the head sideways, which is
/// the one thing worse than a small one.
class _SideLabelled extends StatelessWidget {
  const _SideLabelled({
    required this.child,
    required this.inset,
    required this.overlay,
    this.leftOnLeft = true,
  });

  final Widget child;
  final double inset;
  final bool overlay;

  /// Whether the user's left is the one drawn on the screen's left.
  final bool leftOnLeft;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyle.labelTiny.copyWith(
      color: AppColors.textSecondary,
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        if (overlay)
          child
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: child,
          ),
        // Centred in the gutter rather than jammed against the screen edge,
        // which is where left: 0 alone put them.
        Positioned(
          top: 0,
          left: 0,
          width: inset,
          child: Text(
            leftOnLeft ? 'L' : 'R',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          width: inset,
          child: Text(
            leftOnLeft ? 'R' : 'L',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }
}
