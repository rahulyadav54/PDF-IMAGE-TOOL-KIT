import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pdf_image_toolbox/core/constants/product_ids.dart';
import 'package:pdf_image_toolbox/shared/services/purchase_verifier.dart';

void main() {
  group('PurchaseVerifier', () {
    test('recognizes configured Pro products', () {
      expect(PurchaseVerifier.isProProduct(ProductIds.proLifetime), isTrue);
      expect(PurchaseVerifier.isProProduct(ProductIds.proMonthly), isTrue);
      expect(PurchaseVerifier.isProProduct('unknown_product'), isFalse);
    });

    test('grants Pro only for purchased or restored Pro products', () {
      final purchase = PurchaseDetails(
        productID: ProductIds.proLifetime,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'google_play',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );

      expect(PurchaseVerifier.shouldGrantPro(purchase), isTrue);
    });

    test('rejects purchases without verification data', () {
      final purchase = PurchaseDetails(
        productID: ProductIds.proLifetime,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'google_play',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );

      expect(PurchaseVerifier.shouldGrantPro(purchase), isFalse);
    });

    test('rejects canceled or unknown products', () {
      final purchase = PurchaseDetails(
        productID: 'unknown_product',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'google_play',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );

      expect(PurchaseVerifier.shouldGrantPro(purchase), isFalse);
    });
  });
}
