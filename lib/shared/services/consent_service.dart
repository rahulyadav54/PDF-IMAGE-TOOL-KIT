import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_config.dart';

/// Requests ad consent (UMP) before initializing Mobile Ads where required.
class ConsentService {
  ConsentService._();

  static const _timeout = Duration(seconds: 8);

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

  /// Requests consent info and shows the form when required by the user's region.
  static Future<void> requestConsentIfNeeded() async {
    if (!AdConfig.enabled || !isPlatformSupported || isTestEnvironment) return;

    try {
      await _requestConsent().timeout(_timeout);
    } catch (error) {
      debugPrint('Consent request failed or timed out: $error');
    }
  }

  static Future<void> _requestConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadAndShowConsentFormIfRequired((_) {
              if (!completer.isCompleted) completer.complete();
            });
          } else if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }
      },
      (error) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }
}
