import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/ad_config.dart';
import '../../core/constants/ad_unit_ids.dart';
import 'ad_frequency_policy.dart';
import 'entitlement_service.dart';

final adServiceProvider = Provider<AdService>((ref) => AdService(ref));

/// Centralized Google Mobile Ads integration.
class AdService {
  AdService(this._ref);

  final Ref _ref;
  final AdFrequencyPolicy _frequencyPolicy = const AdFrequencyPolicy();

  static const _lastInterstitialKey = 'last_interstitial_shown_at';
  static const _initTimeout = Duration(seconds: 10);

  static bool _initialized = false;
  static Future<void>? _initializeFuture;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

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

  static Future<void> initialize() {
    if (!AdConfig.enabled) return Future.value();
    _initializeFuture ??= _initializeInternal();
    return _initializeFuture!;
  }

  /// Waits until Mobile Ads is ready (or times out). Never throws.
  static Future<bool> waitUntilReady() async {
    if (!AdConfig.enabled) return false;
    try {
      await initialize().timeout(_initTimeout);
      return _initialized;
    } catch (error) {
      debugPrint('AdMob waitUntilReady failed: $error');
      return false;
    }
  }

  static Future<void> ensureInitialized() async {
    if (!AdConfig.enabled || _initialized) return;
    await initialize();
  }

  static Future<void> _initializeInternal() async {
    if (!isPlatformSupported || isTestEnvironment) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (error, stack) {
      debugPrint('MobileAds initialization failed: $error\n$stack');
    }
  }

  Future<bool> shouldShowAds() async {
    if (!AdConfig.enabled || !isPlatformSupported || isTestEnvironment) {
      return false;
    }
    if (!_initialized) return false;

    try {
      final entitlements =
          await _ref.read(entitlementServiceProvider).getEntitlements();
      return !entitlements.adsRemoved;
    } catch (error) {
      debugPrint('shouldShowAds failed: $error');
      return false;
    }
  }

  Future<void> preloadInterstitial() async {
    if (!AdConfig.enabled) return;

    try {
      if (!await waitUntilReady()) return;
      if (!await shouldShowAds()) return;
      if (_interstitialAd != null || _isLoadingInterstitial) return;

      _isLoadingInterstitial = true;
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (_) {
            _isLoadingInterstitial = false;
          },
        ),
      );
    } catch (error) {
      _isLoadingInterstitial = false;
      debugPrint('preloadInterstitial failed: $error');
    }
  }

  Future<void> showInterstitialIfEligible() async {
    if (!AdConfig.enabled) return;

    try {
      if (!await waitUntilReady()) return;
      if (!await shouldShowAds()) return;
      if (!await _canShowByFrequency()) return;

      final ad = _interstitialAd;
      if (ad == null) {
        await preloadInterstitial();
        return;
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (dismissedAd) {
          dismissedAd.dispose();
          _interstitialAd = null;
          unawaited(preloadInterstitial());
        },
        onAdFailedToShowFullScreenContent: (failedAd, _) {
          failedAd.dispose();
          _interstitialAd = null;
          unawaited(preloadInterstitial());
        },
      );

      await ad.show();
      await _recordInterstitialShown();
    } catch (error) {
      debugPrint('showInterstitialIfEligible failed: $error');
    }
  }

  Future<BannerAd?> buildBannerAd(BannerAdListener listener) async {
    if (!AdConfig.enabled) return null;

    try {
      if (!await waitUntilReady()) return null;
      if (!await shouldShowAds()) return null;

      return BannerAd(
        adUnitId: AdUnitIds.banner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: listener,
      );
    } catch (error) {
      debugPrint('buildBannerAd failed: $error');
      return null;
    }
  }

  Future<bool> _canShowByFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastInterstitialKey);
      if (raw == null) return true;

      final lastShown = DateTime.tryParse(raw);
      return _frequencyPolicy.canShow(lastShown);
    } catch (_) {
      return false;
    }
  }

  Future<void> _recordInterstitialShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastInterstitialKey,
        DateTime.now().toIso8601String(),
      );
    } catch (error) {
      debugPrint('recordInterstitialShown failed: $error');
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
