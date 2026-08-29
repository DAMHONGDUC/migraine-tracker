part of 'account_screen.dart';

/// The editable name plus the read-only facts. Email and "member since"
/// come from the provider and the account document — nothing to edit there.
class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.user, required this.profile});

  final AuthUser? user;
  final UserProfile? profile;

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await DisplayNameDialog(
      initial: profile?.displayName ?? user?.displayName,
    ).show(context);

    if (name == null) return;
    await ref.read(accountControllerProvider).updateDisplayName(name);
    if (context.mounted) {
      SdSnackBarUtilsV2.success(context, l10n.accountNameUpdated);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final String? name = profile?.displayName ?? user?.displayName;
    final String? email = profile?.email ?? user?.email;
    final DateTime? createdAt = profile?.createdAt;

    return Column(
      children: <Widget>[
        ListTile(
          leading: SdIconV2(icon: AppIconConstant.profileName, size: AppIconSize.row),
          title: Text(l10n.accountName, style: AppTextStyle.bodyLarge),
          subtitle: Text(
            name ?? l10n.accountNoName,
            style: AppTextStyle.bodyMedium.secondary,
          ),
          trailing: SdIconV2(icon: AppIconConstant.edit, size: AppIconSize.row),
          onTap: () => _editName(context, ref),
        ),
        ListTile(
          leading: SdIconV2(icon: AppIconConstant.profileEmail, size: AppIconSize.row),
          title: Text(l10n.accountEmail, style: AppTextStyle.bodyLarge),
          subtitle: Text(
            // Apple only sends the email on the very first sign-in, so it can genuinely be missing.
            email ?? l10n.accountEmailUnknown,
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ),
        if (createdAt != null)
          ListTile(
            leading: SdIconV2(icon: AppIconConstant.profileCreated, size: AppIconSize.row),
            title: Text(l10n.accountMemberSince, style: AppTextStyle.bodyLarge),
            subtitle: Text(
              DateFormat.yMMMMd(l10n.localeName).format(createdAt.toLocal()),
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ),
      ],
    );
  }
}
