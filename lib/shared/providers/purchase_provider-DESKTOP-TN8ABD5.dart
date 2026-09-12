import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/purchase_flow_event.dart';
import '../services/purchase_service.dart';

class PurchaseUiState {
  const PurchaseUiState({
    this.isInitialized = false,
    this.storeAvailable = false,
    this.isLoadingProducts = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.products = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isInitialized;
  final bool storeAvailable;
  final bool isLoadingProducts;
  final bool isPurchasing;
  final bool isRestoring;
  final List<ProductDetails> products;
  final String? errorMessage;
  final String? successMessage;

  ProductDetails? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  PurchaseUiState copyWith({
    bool? isInitialized,
    bool? storeAvailable,
    bool? isLoadingProducts,
    bool? isPurchasing,
    bool? isRestoring,
    List<ProductDetails>? products,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PurchaseUiState(
      isInitialized: isInitialized ?? this.isInitialized,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      products: products ?? this.products,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }
}

final purchaseUiProvider =
    StateNotifierProvider<PurchaseUiNotifier, PurchaseUiState>(
  PurchaseUiNotifier.new,
);

class PurchaseUiNotifier extends StateNotifier<PurchaseUiState> {
  PurchaseUiNotifier(this._ref) : super(const PurchaseUiState()) {
    _eventsSubscription = _ref.read(purchaseServiceProvider).events.listen(
      _onPurchaseEvent,
    );
  }

  final Ref _ref;
  StreamSubscription<PurchaseFlowEvent>? _eventsSubscription;

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final service = _ref.read(purchaseServiceProvider);
      await service.initialize();
      await loadProducts();
    } catch (_) {
      state = state.copyWith(
        isInitialized: true,
        storeAvailable: false,
        isLoadingProducts: false,
      );
    }
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoadingProducts: true, clearMessages: true);
    try {
      final service = _ref.read(purchaseServiceProvider);
      final products = await service.loadProducts();
      state = state.copyWith(
        isInitialized: true,
        storeAvailable: service.isStoreAvailable,
        isLoadingProducts: false,
        products: products,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingProducts: false,
        errorMessage: 'Unable to load purchase options. Please try again.',
      );
    }
  }

  Future<void> purchase(String productId) async {
    final product = state.productById(productId);
    if (product == null) {
      state = state.copyWith(
        errorMessage: 'This product is not available in the store yet.',
      );
      return;
    }

    state = state.copyWith(isPurchasing: true, clearMessages: true);
    try {
      await _ref.read(purchaseServiceProvider).purchase(product);
    } catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: 'Purchase could not be started. Please try again.',
      );
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isRestoring: true, clearMessages: true);
    try {
      await _ref.read(purchaseServiceProvider).restorePurchases();
    } catch (_) {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: 'Unable to restore purchases. Please try again.',
      );
    }
  }

  void _onPurchaseEvent(PurchaseFlowEvent event) {
    state = state.copyWith(
      isPurchasing: false,
      isRestoring: false,
      errorMessage: event.errorMessage,
      successMessage: event.successMessage,
      clearMessages: event.errorMessage == null && event.successMessage == null,
    );
  }
}
