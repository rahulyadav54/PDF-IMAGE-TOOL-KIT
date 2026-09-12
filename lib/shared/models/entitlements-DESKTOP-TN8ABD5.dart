/// Feature access flags for the app.
class Entitlements {
  const Entitlements({
    this.isPro = true,
    this.batchProcessing = true,
    this.premiumCompression = true,
    this.adsRemoved = true,
    this.dailyLimit = -1,
  });

  final bool isPro;
  final bool batchProcessing;
  final bool premiumCompression;
  final bool adsRemoved;
  final int dailyLimit;

  /// Full access for every user — no payment required.
  static const Entitlements premium = Entitlements();

  /// Legacy free tier (kept for tests only).
  static const Entitlements free = Entitlements(
    isPro: false,
    batchProcessing: false,
    premiumCompression: false,
    adsRemoved: false,
    dailyLimit: 5,
  );

  bool canPerformOperation(int operationsUsedToday) {
    if (dailyLimit < 0) return true;
    return operationsUsedToday < dailyLimit;
  }

  int remainingOperations(int operationsUsedToday) {
    if (dailyLimit < 0) return -1;
    return (dailyLimit - operationsUsedToday).clamp(0, dailyLimit);
  }

  bool canBatchProcess(int fileCount, {required int freeBatchFileLimit}) {
    if (batchProcessing) return fileCount > 0;
    return fileCount > 0 && fileCount <= freeBatchFileLimit;
  }

  int batchFileLimit({required int freeBatchFileLimit}) {
    return batchProcessing ? -1 : freeBatchFileLimit;
  }
}
