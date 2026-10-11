/// CPU wall-clock samples. Empty populations have no timing, not zero cost.
class PhaseStats {
  final List<double> _samples = [];

  int get count => _samples.length;

  void add(double ms) {
    if (!ms.isFinite || ms < 0) {
      throw ArgumentError.value(ms, 'ms', 'Expected a finite nonnegative time');
    }
    _samples.add(ms);
  }

  double get mean => _samples.isEmpty
      ? double.nan
      : _samples.reduce((a, b) => a + b) / _samples.length;

  double _percentile(double p) {
    if (_samples.isEmpty) return double.nan;
    final sorted = List<double>.from(_samples)..sort();
    // Preserve the original benchmark's nearest-index percentile convention.
    return sorted[((sorted.length - 1) * p).round()];
  }

  double get p50 => _percentile(0.5);
  double get p95 => _percentile(0.95);
  double get p99 => _percentile(0.99);
  double get max =>
      _samples.isEmpty ? double.nan : _samples.reduce((a, b) => a > b ? a : b);

  Map<String, Object?> toJson() => {
    'samples': count,
    'mean': count == 0 ? null : mean,
    'p50': count == 0 ? null : p50,
    'p95': count == 0 ? null : p95,
    'p99': count == 0 ? null : p99,
    'max': count == 0 ? null : max,
  };
}
