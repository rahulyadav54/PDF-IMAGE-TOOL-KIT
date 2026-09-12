import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ad_config.dart';
import '../services/ad_service.dart';

/// Triggers a post-completion interstitial once when a result screen opens.
class CompletionAdTrigger extends ConsumerStatefulWidget {
  const CompletionAdTrigger({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CompletionAdTrigger> createState() => _CompletionAdTriggerState();
}

class _CompletionAdTriggerState extends ConsumerState<CompletionAdTrigger> {
  @override
  void initState() {
    super.initState();
    if (AdConfig.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref.read(adServiceProvider).showInterstitialIfEligible(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
