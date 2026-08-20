part of 'attack_detail_screen.dart';

/// When the attack happened, and how bad it was — the two things the rest of
/// the screen is about.
class _Header extends StatelessWidget {
  const _Header({required this.attack});

  final Attack attack;

  /// How far the list scrolls before the header is gone and the app bar has
  /// to take over. The disc is the tallest thing in the row, so it is the
  /// header's height; shared with [_CompactHeader] so the swap happens
  /// exactly as the real one leaves rather than at a number near it.
  static double get height => SdSpacingConstant.r64;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.yMMMMEEEEd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return Row(
      children: [
        IntensityDisc(value: attack.intensity, size: height),
        SizedBox(width: SdSpacingConstant.w16),
        Expanded(child: Text(when, style: AppTextStyle.titleMedium)),
      ],
    );
  }
}

/// The same two facts, sized for the app bar.
///
/// **A shorter date on purpose.** The header can spend a line on "Thursday,
/// August 20, 2026 at 2:30 PM"; a bar with a back button on one side and a
/// delete on the other cannot, and an ellipsis through a weekday tells the
/// user nothing. This drops the weekday and the long month instead of
/// truncating them.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.attack, super.key});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final String when = DateFormat.yMMMd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IntensityDisc(value: attack.intensity, size: SdSpacingConstant.r28),
        SizedBox(width: SdSpacingConstant.w8),
        Flexible(
          child: Text(
            when,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.titleMedium,
          ),
        ),
      ],
    );
  }
}

/// Swaps the app bar's title for [_CompactHeader] once [_Header] has scrolled
/// out from under it.
///
/// **It listens rather than rebuilding the screen.** The flag lives in a
/// `ValueNotifier` the scroll listener writes and only this widget reads, so
/// a scroll repaints the bar's title and nothing else — the list, the head
/// diagram and every row underneath are untouched.
class _ScrollAwareTitle extends StatelessWidget {
  const _ScrollAwareTitle({
    required this.collapsed,
    required this.attack,
    required this.title,
  });

  final ValueListenable<bool> collapsed;
  final Attack? attack;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: collapsed,
      builder: (BuildContext context, bool isCollapsed, Widget? child) {
        final Attack? a = attack;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          // Fade only, no slide: the bar is 56pt of chrome and a title
          // sliding through it reads as a glitch rather than as a transition.
          transitionBuilder: (Widget child, Animation<double> animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isCollapsed && a != null
              ? _CompactHeader(key: const ValueKey<bool>(true), attack: a)
              : KeyedSubtree(key: const ValueKey<bool>(false), child: title),
        );
      },
    );
  }
}
