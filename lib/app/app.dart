import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../l10n/app_localizations.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/recent_files_provider.dart';
import '../shared/services/cache_maintenance_service.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/incoming_share_service.dart';
import '../shared/services/shortcut_route_service.dart';
import '../shared/widgets/app_lock_gate.dart';
import '../shared/widgets/app_splash_screen.dart';
import 'router.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class PdfImageToolboxApp extends ConsumerStatefulWidget {
  const PdfImageToolboxApp({super.key});

  @override
  ConsumerState<PdfImageToolboxApp> createState() => _PdfImageToolboxAppState();
}

class _PdfImageToolboxAppState extends ConsumerState<PdfImageToolboxApp> {
  var _showSplash = true;
  bool _splashComplete = false;
  IncomingShareService? _incomingShareService;

  @override
  void dispose() {
    _incomingShareService?.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    if (!mounted) return;

    setState(() {
      _showSplash = false;
      _splashComplete = true;
    });

    _startIncomingShareListener();
    _handleLaunchRoutes();
    ref.read(homeWidgetServiceProvider).initialize();
    unawaited(ref.read(cacheMaintenanceServiceProvider).runMaintenance());
  }

  Future<void> _handleLaunchRoutes() async {
    await ref.read(shortcutRouteProvider.notifier).loadInitialRoute();
    final shortcut = ref.read(shortcutRouteProvider);
    if (shortcut != null && mounted) {
      ref.read(shortcutRouteProvider.notifier).consume();
      context.go(shortcut);
      return;
    }

    final widgetRoute = await ref.read(homeWidgetServiceProvider).getLaunchedRoute();
    if (widgetRoute != null && mounted) {
      context.go(widgetRoute);
    }
  }

  Future<void> _startIncomingShareListener() async {
    final service = ref.read(incomingShareServiceProvider);
    _incomingShareService = service;
    await service.startListening(onOutcome: _handleIncomingShareOutcome);
  }

  Future<void> _handleIncomingShareOutcome(IncomingShareOutcome outcome) async {
    if (!mounted || !_splashComplete) return;

    if (outcome.hasAdded) {
      await ref.read(recentFilesProvider.notifier).refresh();
      if (!mounted) return;

      if (outcome.importedFiles.length == 1) {
        context.go('/open-with', extra: outcome.importedFiles.first);
        return;
      }

      context.go('/');

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            outcome.addedCount == 1
                ? 'Added to Recent documents'
                : '${outcome.addedCount} files added to Recent documents',
          ),
        ),
      );
      return;
    }

    if (outcome.skippedUnsupported > 0) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('This file type is not supported yet.')),
      );
      return;
    }

    if (outcome.failed > 0) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Could not import the shared file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(themePreferenceProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConstants.appNameShort,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themePreference.themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (!_showSplash)
              AppLockGate(child: child ?? const SizedBox.shrink()),
            if (_showSplash) AppSplashScreen(onComplete: _onSplashComplete),
          ],
        );
      },
    );
  }
}
