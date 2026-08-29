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
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SdIconV2(
            icon: icon,
            size: AppIconSize.xxLarge,
            color: context.colorScheme.primary,
          ),
          SizedBox(height: SdSpacingConstant.h24),
          Text(title, style: AppTextStyle.headlineMedium.w600),
          SizedBox(height: SdSpacingConstant.h12),
          Text(body, style: AppTextStyle.bodyLarge.secondary),
          if (footer != null) ...[
            SizedBox(height: SdSpacingConstant.h24),
            footer!,
          ],
        ],
      ),
    );
  }
}
