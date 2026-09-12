class PurchaseFlowEvent {
  const PurchaseFlowEvent({
    this.errorMessage,
    this.successMessage,
    this.flowFinished = true,
    this.proRestored = false,
  });

  final String? errorMessage;
  final String? successMessage;
  final bool flowFinished;
  final bool proRestored;
}
