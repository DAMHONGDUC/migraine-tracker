part of 'login_screen.dart';

/// What signing in does and does not do with health data.
///
/// Hard rule 1 requires this to be stated where the user decides, and it
/// must stay accurate: today an account uploads nothing but the alert
/// settings the user already opted into. When encrypted attack sync ships,
/// this copy changes with it — not before.
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
