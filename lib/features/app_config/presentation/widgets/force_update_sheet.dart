import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/app_update_config.dart';
import '../../providers.dart';

/// The blocking sheet: the app behind it, and nothing to touch but Update.
///
/// **A layer over the app, not a pushed route** (owner's report, 2026-09-21:
/// "it shows, then it is gone once the dashboard opens"). It was a
/// non-dismissible bottom sheet pushed on `rootNavigatorKeyProvider` — which
/// is go_router's OWN navigator. The splash finishes its work and calls
/// `context.go('/dashboard')`, go_router rebuilds the stack, and the modal
/// route goes with it; the wrapper had already marked the sheet as shown, so
/// nothing put it back. A sheet that only survives until the first navigation
/// is not a block.
///
/// So the same sheet is drawn as a `Stack` over [child] instead: there is no
/// route to pop, nothing that can get out of step with the flag, and no
/// navigator that has to exist first. **It keeps every part of the modal it
/// replaced** — `SdThemeV2.barrier` over the app, `surfaceModal` panel, the
/// r22 top corners, the `contentMaxWidth` cap that stops it spanning a
/// landscape iPad, and no drag handle, because a handle promises a swipe that
/// must not work.
///
/// The barrier is what makes it a block rather than a decoration: it takes
/// every pointer on the screen, so the app stays visible underneath and
/// entirely untouchable, and Update is the only thing left to press.
class ForceUpdateSheet extends ConsumerWidget {
  const ForceUpdateSheet({
    required this.config,
    required this.child,
    super.key,
  });

  final PlatformUpdateConfig config;

  /// The app, drawn behind the barrier — visible, and out of reach.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
    children: <Widget>[
      child,
      // Opaque to hit-testing on purpose: `dismissible: false` stops it
      // closing the sheet, and being there at all is what stops a tap
      // reaching the dashboard behind it.
      ModalBarrier(dismissible: false, color: context.sdTheme.barrier),
      Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: SdBreakpointV2.contentMaxWidth),
          child: Material(
            color: context.sdTheme.surfaceModal,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(SdSpacingConstant.r22),
              ),
            ),
            child: _ForceUpdatePanel(config: config),
          ),
        ),
      ),
    ],
  );
}

/// What is inside the sheet.
class _ForceUpdatePanel extends ConsumerWidget {
  const _ForceUpdatePanel({required this.config});

  final PlatformUpdateConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SdContentPaddingV2.horizontal,
          SdSpacingConstant.h24,
          SdContentPaddingV2.horizontal,
          SdSpacingConstant.h16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SdIconV2(
              icon: AppIconConstant.appUpdate,
              size: AppIconSize.xLarge,
              color: context.colorScheme.primary,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            Text(
              l10n.forceUpdateTitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.titleLarge.w600,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              l10n.forceUpdateBody,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            if (config.buildName.isNotEmpty) ...<Widget>[
              SizedBox(height: SdSpacingConstant.h8),
              Text(
                l10n.forceUpdateVersion(config.buildName),
                textAlign: TextAlign.center,
                style: AppTextStyle.labelSmall.secondary,
              ),
            ],
            SizedBox(height: SdSpacingConstant.h24),
            _UpdateButton(label: l10n.forceUpdateCta),
          ],
        ),
      ),
    );
  }
}

/// Separate widget so a failed launch can flip its own state without rebuilding the sheet around it.
///
/// **The failure is said inside the sheet, not in a snackbar** (2026-09-21).
/// `SdSnackBarUtilsV2` draws into the root overlay, which lives inside the
/// navigator — and the sheet is a layer ABOVE that navigator now, so a message
/// raised here would be painted behind the very barrier that raised it. The
/// sheet is the only thing on screen the user can see or touch, so it is the
/// only place a message can go.
class _UpdateButton extends ConsumerStatefulWidget {
  const _UpdateButton({required this.label});

  final String label;

  @override
  ConsumerState<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends ConsumerState<_UpdateButton> {
  bool _failed = false;

  Future<void> _open() async {
    final bool opened = await ref
        .read(forceUpdateControllerProvider.notifier)
        .openStore();

    if (!mounted) return;

    setState(() => _failed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_failed) ...<Widget>[
          Text(
            l10n.forceUpdateStoreFailed,
            textAlign: TextAlign.center,
            style: AppTextStyle.labelSmall.copyWith(
              color: context.colorScheme.error,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h12),
        ],
        SdButtonV2(
          variant: SdButtonVariantV2.primary,
          label: widget.label,
          icon: AppIconConstant.externalLink,
          onPressed: _open,
        ),
      ],
    );
  }
}
