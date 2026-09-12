import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ad_config.dart';
import '../../shared/services/ad_service.dart';
import '../../shared/services/consent_service.dart';

/// Safe app startup — never block or crash the UI on SDK initialization.
class AppBootstrap {
  AppBootstrap._();

  static Future<void> prepare() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Initializes optional third-party SDKs after the first frame is drawn.
  static Future<void> initializeDeferredServices() async {
    if (!AdConfig.enabled) return;

    try {
      await ConsentService.requestConsentIfNeeded();
    } catch (error, stack) {
      debugPrint('Consent init skipped: $error\n$stack');
    }

    try {
      await AdService.initialize();
    } catch (error, stack) {
      debugPrint('AdMob init skipped: $error\n$stack');
    }
  }
}
