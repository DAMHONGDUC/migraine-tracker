part of 'attack_detail_screen.dart';

class _Section extends StatelessWidget {
  const _Section({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: SdSpacingV2.w4,
              bottom: SdSpacingV2.h8,
            ),
            child: Text(title!, style: AppTextStyle.titleSmall.secondary),
          ),
        ],
        Card(child: Column(children: children)),
      ],
    );
  }
}
