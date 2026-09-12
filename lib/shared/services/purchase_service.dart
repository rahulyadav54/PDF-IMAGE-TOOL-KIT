import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/product_ids.dart';
import '../models/purchase_flow_event.dart';
import 'entitlement_service.dart';
import 'purchase_verifier.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Handles in-app purchases, restore flow, and Pro entitlement updates.
class PurchaseService {
  PurchaseService(this._ref);

  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<PurchaseFlowEvent> _eventsController =
      StreamController<PurchaseFlowEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isInitialized = false;
  bool _storeAvailable = false;
  bool _restorePending = false;
  bool _restoredDuringRequest = false;

  bool get isStoreAvailable => _storeAvailable;
  Stream<PurchaseFlowEvent> get events => _eventsController.stream;

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized || !isPlatformSupported || isTestEnvironment) return;

    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      _isInitialized = true;
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {
        _emit(const PurchaseFlowEvent(
          errorMessage: 'Purchase processing failed. Please try again.',
        ));
      },
    );

    _isInitialized = true;
    await _silentlyRevalidateEntitlements();
  }

  /// Re-checks Play purchases on startup without user-facing messages.
  Future<void> _silentlyRevalidateEntitlements() async {
    _restorePending = false;
    _restoredDuringRequest = false;
    try {
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    } catch (_) {
      // Keep cached entitlement if the store is temporarily unavailable.
    }
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!_storeAvailable) return [];

    final response = await _iap.queryProductDetails(ProductIds.all.toSet());
    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response.productDetails;
  }

  Future<void> purchase(ProductDetails product) async {
    if (!_storeAvailable) {
      throw Exception('Store unavailable');
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      throw Exception('Purchase not started');
    }
  }

  Future<bool> restorePurchases() async {
    if (!_storeAvailable) return false;

    _restorePending = true;
    _restoredDuringRequest = false;

    await _iap.restorePurchases();
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    _restorePending = false;

    if (!_restoredDuringRequest) {
      _emit(const PurchaseFlowEvent(
        successMessage: 'No active Pro purchases were found for this account.',
      ));
    }

    return _restoredDuringRequest;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) return;

    if (purchase.status == PurchaseStatus.error) {
      _emit(PurchaseFlowEvent(
        errorMessage: purchase.error?.message ?? 'Purchase failed. Please try again.',
      ));
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      _emit(const PurchaseFlowEvent(flowFinished: true));
      return;
    }

    if (PurchaseVerifier.shouldGrantPro(purchase)) {
      await _ref.read(entitlementServiceProvider).setProStatus(
            true,
            productId: purchase.productID,
            purchaseId: purchase.purchaseID,
          );
      _ref.invalidate(entitlementsProvider);

      if (_restorePending) {
        _restoredDuringRequest = true;
      }

      _emit(PurchaseFlowEvent(
        successMessage: purchase.status == PurchaseStatus.restored
            ? 'Pro access restored successfully.'
            : 'Pro unlocked successfully. Thank you!',
        proRestored: purchase.status == PurchaseStatus.restored,
      ));
    } else if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      _emit(const PurchaseFlowEvent(
        errorMessage: 'Purchase could not be verified.',
      ));
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void _emit(PurchaseFlowEvent event) {
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _eventsController.close();
    _subscription = null;
  }
}
