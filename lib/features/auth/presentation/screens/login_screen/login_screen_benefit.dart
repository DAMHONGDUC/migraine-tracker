part of 'login_screen.dart';

/// One reason to bother with an account. Deliberately concrete — vague
/// "sync your data" copy would over-promise something that does not exist
/// yet (see [_PrivacyDisclosure]).
class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(icon, color: context.colorScheme.primary),
          SizedBox(width: AppSpacingConstant.w16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyle.titleMedium),
                SizedBox(height: AppSpacingConstant.h4),
                Text(body, style: AppTextStyle.bodyMedium.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
