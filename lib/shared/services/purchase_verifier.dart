import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/constants/product_ids.dart';

/// Client-side purchase verification before granting Pro entitlements.
///
/// Production apps should also verify purchases server-side via the
/// Google Play Developer API.
class PurchaseVerifier {
  PurchaseVerifier._();

  static bool isProProduct(String productId) => ProductIds.all.contains(productId);

  static bool shouldGrantPro(PurchaseDetails purchase) {
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return false;
    }

    if (!isProProduct(purchase.productID)) {
      return false;
    }

    return _hasValidVerificationData(purchase);
  }

  static bool _hasValidVerificationData(PurchaseDetails purchase) {
    final data = purchase.verificationData;

    if (data.localVerificationData.isEmpty) {
      return false;
    }

    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          if (data.source != 'google_play') return false;
          if (purchase is GooglePlayPurchaseDetails &&
              purchase.billingClientPurchase.purchaseState !=
                  PurchaseStateWrapper.purchased) {
            return false;
          }
        }
      } catch (_) {
        return false;
      }
    }

    return true;
  }
}
