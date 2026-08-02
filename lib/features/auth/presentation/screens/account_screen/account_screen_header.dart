part of 'account_screen.dart';

/// Avatar, name and email — who you are signed in as, at a glance.
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user, required this.profile});

  final AuthUser? user;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // The profile document wins: it is where an edit made here lands.
    final String? name = profile?.displayName ?? user?.displayName;
    final String? email = profile?.email ?? user?.email;

    return Container(
      // No top gap of its own: AppActionView already applied the screen's.
      padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w16),
      alignment: AlignmentDirectional.center,
      child: Column(
        children: <Widget>[
          _Avatar(photoUrl: profile?.photoUrl ?? user?.photoUrl, name: name),
          SizedBox(height: AppSpacingConstant.h12),
          Text(
            name ?? l10n.accountNoName,
            textAlign: TextAlign.center,
            style: AppTextStyle.titleMedium.w600,
          ),
          if (email != null) ...<Widget>[
            SizedBox(height: AppSpacingConstant.h4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// The provider's picture when there is one, the first letter otherwise —
/// never a broken image box: a failed load falls back to the same initial.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final String initial = (name ?? '?').characters.first.toUpperCase();
    final double size = AppSpacingConstant.r64;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.primary.withValues(alpha: 0.18),
      ),
      child: photoUrl == null
          ? _Initial(initial: initial)
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initial(initial: initial),
            ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: AppTextStyle.headlineSmall.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
