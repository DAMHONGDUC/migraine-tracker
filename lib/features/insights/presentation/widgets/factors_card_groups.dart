part of 'factors_card.dart';

/// The map once it has enough behind it, and what it is still waiting for when it does not.
class _Map extends StatelessWidget {
  const _Map({required this.map});

  final FactorMap map;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (!map.isReady) return _Pending(map: map);

    final List<Widget> groups = <Widget>[
      for (final FactorVerdict verdict in <FactorVerdict>[
        FactorVerdict.trigger,
        FactorVerdict.protector,
        FactorVerdict.notAssociated,
        FactorVerdict.insufficient,
      ])
        if (map.of(verdict) case final List<FactorAssociation> found
            when found.isNotEmpty)
          _Group(verdict: verdict, associations: found),
    ];

    // Every factor ungraded and none associated is possible, and it is an answer rather than an empty card.
    if (groups.isEmpty) {
      return Text(
        l10n.factorsEmpty,
        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < groups.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: InsightCard.stackGap),
          groups[i],
        ],
      ],
    );
  }
}

/// How far along the map's two requirements are. It says both, because a user with four weeks of days and three attacks is waiting on a different thing from one with two attacks a week and no check-ins.
class _Pending extends StatelessWidget {
  const _Pending({required this.map});

  final FactorMap map;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.factorsPending(
            map.answeredDays,
            map.requiredDays,
            map.attacks,
            map.requiredAttacks,
          ),
          style: AppTextStyle.titleSmall,
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          l10n.factorsPendingBody,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// One verdict's factors, under its own heading.
class _Group extends StatelessWidget {
  const _Group({required this.verdict, required this.associations});

  final FactorVerdict verdict;
  final List<FactorAssociation> associations;

  String _heading(AppLocalizations l10n) => switch (verdict) {
    FactorVerdict.trigger => l10n.factorsTriggers,
    FactorVerdict.protector => l10n.factorsProtectors,
    FactorVerdict.notAssociated => l10n.factorsNotAssociated,
    FactorVerdict.insufficient => l10n.factorsInsufficient,
  };

  /// Only the two graded ends take a colour; "no difference" and "not enough days" are statements, not findings.
  Color _colorOf() => switch (verdict) {
    FactorVerdict.trigger => AppColors.intensity(8),
    FactorVerdict.protector => AppColors.primary,
    FactorVerdict.notAssociated ||
    FactorVerdict.insufficient => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _heading(l10n),
          style: AppTextStyle.titleSmall.copyWith(color: _colorOf()),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        for (final FactorAssociation association in associations)
          _Row(association: association),
      ],
    );
  }
}

/// One factor: what it is, and the two numbers behind where it landed.
class _Row extends StatelessWidget {
  const _Row({required this.association});

  final FactorAssociation association;

  static int _percent(double rate) => (rate * 100).round();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(association.factor.label(l10n), style: AppTextStyle.bodyLarge),
          // The working, always: a verdict without its two groups is the app asking to be believed.
          Text(
            l10n.factorsRow(
              _percent(association.attackRateWith),
              association.daysWith,
              _percent(association.attackRateWithout),
              association.daysWithout,
            ),
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
