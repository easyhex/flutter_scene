import 'dart:convert';

import 'package:stress_bench/phase_stats.dart';
import 'package:test/test.dart';

void main() {
  test('empty population cannot be reported as a zero-cost render', () {
    final stats = PhaseStats();
    expect(stats.toJson()['samples'], 0);
    expect(stats.toJson()['p95'], isNull);
    expect(jsonDecode(jsonEncode(stats.toJson()))['mean'], isNull);
  });

  test('percentiles preserve the original nearest-index convention', () {
    final stats = PhaseStats();
    for (var i = 99; i >= 0; i--) {
      stats.add(i.toDouble());
    }
    expect(stats.count, 100);
    expect(stats.mean, 49.5);
    expect(stats.p50, 50);
    expect(stats.p95, 94);
    expect(stats.p99, 98);
    expect(stats.max, 99);
  });

  test('invalid samples fail instead of contaminating benchmark JSON', () {
    final stats = PhaseStats();
    for (final sample in [double.nan, double.infinity, -1.0]) {
      expect(() => stats.add(sample), throwsArgumentError);
    }
    expect(stats.count, 0);
  });
}
