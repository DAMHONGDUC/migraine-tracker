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
            margin: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w4),
            width: i == current ? SdSpacingConstant.w20 : SdSpacingConstant.w8,
            height: SdSpacingConstant.h8,
            decoration: BoxDecoration(
              color: i == current
                  ? context.colorScheme.primary
                  : context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
            ),
          ),
      ],
    );
  }
}
