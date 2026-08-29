import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/health_range.dart';

/// Which range a health chart is showing.
class StepRangeController extends Notifier<HealthRange> {
  @override
  HealthRange build() => HealthRange.week;

  void set(HealthRange range) {
    SdLogger.action(LogTagConstant.insights, 'Step range', range.name);
    state = range;
  }
}

class SleepRangeController extends Notifier<HealthRange> {
  @override
  HealthRange build() => HealthRange.week;

  void set(HealthRange range) {
    SdLogger.action(LogTagConstant.insights, 'Sleep range', range.name);
    state = range;
  }
}
