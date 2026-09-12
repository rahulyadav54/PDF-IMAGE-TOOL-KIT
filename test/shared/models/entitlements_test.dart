import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/models/entitlements.dart';

void main() {
  group('Entitlements', () {
    test('free tier limits operations', () {
      const free = Entitlements.free;
      expect(free.canPerformOperation(0), isTrue);
      expect(free.canPerformOperation(4), isTrue);
      expect(free.canPerformOperation(5), isFalse);
      expect(free.remainingOperations(3), 2);
    });

    test('premium tier has no limits', () {
      const premium = Entitlements.premium;
      expect(premium.canPerformOperation(100), isTrue);
      expect(premium.remainingOperations(100), -1);
      expect(premium.adsRemoved, isTrue);
    });

    test('batch processing limits for free tier', () {
      const free = Entitlements.free;
      expect(free.canBatchProcess(3, freeBatchFileLimit: 3), isTrue);
      expect(free.canBatchProcess(4, freeBatchFileLimit: 3), isFalse);
      expect(free.batchFileLimit(freeBatchFileLimit: 3), 3);
      expect(Entitlements.premium.batchFileLimit(freeBatchFileLimit: 3), -1);
    });
  });
}
