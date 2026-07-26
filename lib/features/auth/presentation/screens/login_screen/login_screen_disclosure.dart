part of 'login_screen.dart';

/// Hard rule 1: state this where the user decides, and keep it true. Today
/// an account uploads nothing beyond the alert settings they opted into.
/// The copy changes when encrypted sync ships — not before.
class _PrivacyDisclosure extends StatelessWidget {
  const _PrivacyDisclosure();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacingConstant.w16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(
            Icons.lock_outline,
            size: AppSpacingConstant.r20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacingConstant.w12),
          Expanded(
            child: Text(
              context.l10n.loginPrivacyNote,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
