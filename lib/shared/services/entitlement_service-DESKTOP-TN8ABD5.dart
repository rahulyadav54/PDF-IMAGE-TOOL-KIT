import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entitlements.dart';

final entitlementServiceProvider =
    Provider<EntitlementService>((ref) => EntitlementService());

final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  return service.getEntitlements();
});

/// All users receive full premium access — no paywalls or daily limits.
class EntitlementService {
  Future<Entitlements> getEntitlements() async => Entitlements.premium;

  Future<bool> isProUser() async => true;

  Future<void> setProStatus(
    bool isPro, {
    String? productId,
    String? purchaseId,
  }) async {}

  Future<void> clearProStatus() async {}

  Future<int> getOperationsUsedToday() async => 0;

  Future<bool> canPerformOperation() async => true;

  Future<bool> canRunBatch(int fileCount) async => fileCount > 0;

  Future<void> recordOperation() async {}
}
