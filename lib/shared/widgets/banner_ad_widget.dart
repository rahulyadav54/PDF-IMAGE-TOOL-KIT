import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_config.dart';
import '../services/ad_service.dart';

/// Home-screen banner ad. Hidden for Pro users and when ads are disabled.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    if (AdConfig.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
    }
  }

  Future<void> _loadBanner() async {
    try {
      final adService = ref.read(adServiceProvider);
      final banner = await adService.buildBannerAd(
        BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _shouldShow = true;
            });
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _isLoaded = false;
                _shouldShow = false;
              });
            }
          },
        ),
      );

      if (!mounted) return;

      if (banner == null) {
        setState(() => _shouldShow = false);
        return;
      }

      banner.load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoaded = false;
          _shouldShow = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.enabled || !_shouldShow || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sponsored',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ],
        ),
      ),
    );
  }
}
