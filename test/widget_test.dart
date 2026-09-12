import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/app/app.dart';
import 'package:pdf_image_toolbox/shared/models/entitlements.dart';
import 'package:pdf_image_toolbox/shared/providers/recent_files_provider.dart';
import 'package:pdf_image_toolbox/shared/services/entitlement_service.dart';
import 'package:pdf_image_toolbox/shared/services/starred_files_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads redesigned home screen', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentFilesProvider.overrideWith(() => _EmptyRecentFilesNotifier()),
          starredPathsProvider.overrideWith((ref) => _EmptyStarredPathsNotifier()),
          entitlementsProvider.overrideWith((ref) async => Entitlements.free),
        ],
        child: const PdfImageToolboxApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDF Editor & Tools'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
    expect(find.text('Start with'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Recent files'), findsOneWidget);
    expect(find.text('Your tools'), findsOneWidget);
    expect(find.text('Scan to PDF'), findsWidgets);
    expect(find.text('Compress PDF'), findsWidgets);
  });
}

class _EmptyRecentFilesNotifier extends RecentFilesNotifier {
  @override
  Future<RecentFilesState> build() async => const RecentFilesState(files: []);
}

class _EmptyStarredPathsNotifier extends StarredPathsNotifier {
  _EmptyStarredPathsNotifier() : super(_NoOpStarredFilesService());
}

class _NoOpStarredFilesService extends StarredFilesService {
  @override
  Future<Set<String>> load() async => {};

  @override
  Future<void> save(Set<String> paths) async {}
}
