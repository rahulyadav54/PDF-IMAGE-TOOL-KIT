/// Controls how often interstitial ads may be shown.
class AdFrequencyPolicy {
  const AdFrequencyPolicy({
    this.minInterval = const Duration(minutes: 3),
  });

  final Duration minInterval;

  bool canShow(DateTime? lastShownAt, {DateTime? now}) {
    if (lastShownAt == null) return true;
    final current = now ?? DateTime.now();
    return current.difference(lastShownAt) >= minInterval;
  }
}
