import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'app_logo.dart';
import 'company_branding.dart';

/// Branded splash shown while the app finishes its first frame setup.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1600), widget.onComplete);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF1B6EF3);
    const darkNavy = Color(0xFF0D1B2A);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [darkNavy, Color(0xFF123A7A), brandBlue],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                ScaleTransition(
                  scale: _scale,
                  child: const AppLogo(size: 128, borderRadius: 28),
                ),
                const SizedBox(height: 28),
                Text(
                  AppConstants.appNameShort,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
                const SizedBox(height: 36),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: CompanyBranding(
                  style: CompanyBrandingStyle.splash,
                  lightText: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
