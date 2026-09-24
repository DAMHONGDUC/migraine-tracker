import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/error_view_config.dart';
import '../../domain/enums/error_view_type.dart';
import '../../providers.dart';

/// Replaces the whole app while the owner has a notice switched on.
///
/// A layer in the tree rather than a pushed route, for `BlockedAccountGate`'s
/// reason: it clears the moment the owner switches it off, and a plain `if`
/// cannot get out of step with the flag the way a route that has to be popped
/// can. It sits inside `MaterialApp.builder`, so it has the theme and the
/// localizations.
///
/// **Where it sits between the other two gates is the design.** Inside
/// `ForceUpdateWrapper`, because an outage the owner is about to fix and a
/// build the store can fix both need one to win and the store link is the one
/// that helps either way — the same call force update already wins against the
/// block. Outside `BlockedAccountGate`, because a notice is addressed to
/// everybody and the block to one account: telling a blocked user that the
/// backend is down is the more useful of the two sentences.
class RemoteErrorGate extends ConsumerWidget {
  const RemoteErrorGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ErrorViewConfig? notice = ref.watch(remoteErrorViewProvider);

    if (notice == null) return child;

    return RemoteErrorView(config: notice);
  }
}

/// The notice itself, in the owner's words.
///
/// **Not `SdErrorViewV2`, and the reason is the shape rather than the look.**
/// That widget draws one body line plus a `detail` row meant for a raw failure
/// outside production; this one draws two body lines the owner wrote for the
/// user, and colours its glyph by severity. Bending `detail` into a second
/// subtitle would leave the next reader of either file believing something
/// untrue about the other.
class RemoteErrorView extends StatelessWidget {
  const RemoteErrorView({required this.config, super.key});

  final ErrorViewConfig config;

  @override
  Widget build(BuildContext context) {
    final bool isWarning = config.type == ErrorViewType.warning;

    return Material(
      color: context.colorScheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          // Centres while it fits and scrolls once it does not. The owner types
          // this copy with no length limit, into the one screen that has no
          // other way to say anything — so an overflow here is the whole
          // screen, not a clipped corner.
          builder: (BuildContext context, BoxConstraints constraints) =>
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                  vertical: SdSpacingConstant.h24,
                ),
                child: ConstrainedBox(
                  // Minus the padding above, or the centre sits low by it.
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - SdSpacingConstant.h24 * 2,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SdIconV2(
                          icon: isWarning
                              ? AppIconConstant.warning
                              : AppIconConstant.error,
                          size: AppIconSize.xLarge,
                          color: isWarning
                              ? AppColors.warning
                              : context.colorScheme.error,
                        ),
                        SizedBox(height: SdSpacingConstant.h16),
                        Text(
                          config.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.titleLarge.w600,
                        ),
                        // Only the lines that carry text: the owner may have
                        // one thing to say, or three, and an empty Text still
                        // takes its gap.
                        if (config.subtitle1.isNotEmpty) ...<Widget>[
                          SizedBox(height: SdSpacingConstant.h8),
                          Text(
                            config.subtitle1,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bodyMedium.secondary,
                          ),
                        ],
                        if (config.subtitle2.isNotEmpty) ...<Widget>[
                          SizedBox(height: SdSpacingConstant.h8),
                          Text(
                            config.subtitle2,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bodyMedium.secondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
