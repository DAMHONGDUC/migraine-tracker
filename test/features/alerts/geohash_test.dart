import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/alerts/domain/services/geohash.dart';

void main() {
  test('matches the classic ezs42 vector (same as the backend decoder)', () {
    expect(encodeGeohash(42.605, -5.603), 'ezs42');
  });

  test('encodes Hanoi into the cell the backend decodes back', () {
    // functions/test/geohash.test.ts asserts w7er8 ≈ (21.03, 105.85).
    expect(encodeGeohash(21.03, 105.85), 'w7er8');
  });

  test('precision controls the length', () {
    expect(encodeGeohash(0, 0, precision: 7).length, 7);
  });
}
