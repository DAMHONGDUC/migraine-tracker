part of 'onboarding_screen.dart';

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppContentPadding.horizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon: icon,
            size: AppSpacingConstant.r64,
            color: context.colorScheme.primary,
          ),
          SizedBox(height: AppSpacingConstant.h24),
          Text(title, style: AppTextStyle.headlineMedium.w600),
          SizedBox(height: AppSpacingConstant.h12),
          Text(body, style: AppTextStyle.bodyLarge.secondary),
          if (footer != null) ...[
            SizedBox(height: AppSpacingConstant.h24),
            footer!,
          ],
        ],
      ),
    );
  }
}
