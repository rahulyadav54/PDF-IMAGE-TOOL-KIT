import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/entitlements.dart';

final entitlementServiceProvider =
    Provider<EntitlementService>((ref) => EntitlementService());

final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  return service.getEntitlements();
});

/// Tracks Pro status, daily usage limits, and batch limits for free users.
class EntitlementService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Entitlements> getEntitlements() async {
    final isPro = await isProUser();
    return isPro ? Entitlements.premium : Entitlements.free;
  }

  Future<bool> isProUser() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.proStatusKey) ?? false;
  }

  Future<void> setProStatus(
    bool isPro, {
    String? productId,
    String? purchaseId,
  }) async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.proStatusKey, isPro);

    if (isPro) {
      if (productId != null) {
        await prefs.setString(AppConstants.proProductIdKey, productId);
      }
      if (purchaseId != null) {
        await prefs.setString(AppConstants.proPurchaseIdKey, purchaseId);
      }
      return;
    }

    await prefs.remove(AppConstants.proProductIdKey);
    await prefs.remove(AppConstants.proPurchaseIdKey);
  }

  Future<void> clearProStatus() async {
    await setProStatus(false);
  }

  Future<int> getOperationsUsedToday() async {
    final prefs = await _prefs;
    final today = _todayKey();
    final storedDate = prefs.getString(AppConstants.dailyOpsDateKey);
    if (storedDate != today) return 0;
    return prefs.getInt(AppConstants.dailyOpsCountKey) ?? 0;
  }

  Future<bool> canPerformOperation() async {
    final entitlements = await getEntitlements();
    if (entitlements.isPro) return true;
    final used = await getOperationsUsedToday();
    return entitlements.canPerformOperation(used);
  }

  Future<bool> canRunBatch(int fileCount) async {
    final entitlements = await getEntitlements();
    return entitlements.canBatchProcess(
      fileCount,
      freeBatchFileLimit: AppConstants.freeBatchFileLimit,
    );
  }

  Future<void> recordOperation() async {
    if (await isProUser()) return;

    final prefs = await _prefs;
    final today = _todayKey();
    final storedDate = prefs.getString(AppConstants.dailyOpsDateKey);

    if (storedDate != today) {
      await prefs.setString(AppConstants.dailyOpsDateKey, today);
      await prefs.setInt(AppConstants.dailyOpsCountKey, 1);
      return;
    }

    final count = prefs.getInt(AppConstants.dailyOpsCountKey) ?? 0;
    await prefs.setInt(AppConstants.dailyOpsCountKey, count + 1);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
