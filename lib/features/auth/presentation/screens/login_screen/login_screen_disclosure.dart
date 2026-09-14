part of 'login_screen.dart';

/// Hard rule 1: state this where the user decides, and keep it true.
class _PrivacyDisclosure extends StatelessWidget {
  const _PrivacyDisclosure();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SdSpacingConstant.w16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SdIconV2(
            icon: AppIconConstant.locked,
            size: AppIconSize.xSmall,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: SdSpacingConstant.w12),
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
