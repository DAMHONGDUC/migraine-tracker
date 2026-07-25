part of 'onboarding_screen.dart';

class _Dots extends StatelessWidget {
  const _Dots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < OnboardingScreen._pageCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w4),
            width: i == current ? AppSpacingConstant.w20 : AppSpacingConstant.w8,
            height: AppSpacingConstant.h8,
            decoration: BoxDecoration(
              color: i == current
                  ? context.colorScheme.primary
                  : context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacingConstant.r4),
            ),
          ),
      ],
    );
  }
}
