import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/services/ad_frequency_policy.dart';

void main() {
  group('AdFrequencyPolicy', () {
    const policy = AdFrequencyPolicy(minInterval: Duration(minutes: 3));

    test('allows first interstitial', () {
      expect(policy.canShow(null), isTrue);
    });

    test('blocks interstitial inside cooldown window', () {
      final lastShown = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 2);
      expect(policy.canShow(lastShown, now: now), isFalse);
    });

    test('allows interstitial after cooldown window', () {
      final lastShown = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 3);
      expect(policy.canShow(lastShown, now: now), isTrue);
    });
  });
}
