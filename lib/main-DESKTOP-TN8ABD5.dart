import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/error_handling.dart';

Future<void> main() async {
  ErrorHandling.install();
  await AppBootstrap.prepare();

  runApp(
    const ProviderScope(
      child: PdfImageToolboxApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AppBootstrap.initializeDeferredServices());
  });
}
