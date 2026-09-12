import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/app/app.dart';
import 'package:pdf_image_toolbox/shared/providers/recent_files_provider.dart';

void main() {
  testWidgets('App loads redesigned home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentFilesProvider.overrideWith(() => _EmptyRecentFilesNotifier()),
        ],
        child: const PdfImageToolboxApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(find.textContaining('Good'), findsOneWidget);
    expect(find.text('Everything you need for your files.'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Recent documents'), findsOneWidget);
    expect(find.text('Image tools'), findsOneWidget);
    expect(find.text('Scan to PDF'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
  });
}

class _EmptyRecentFilesNotifier extends RecentFilesNotifier {
  @override
  Future<RecentFilesState> build() async => const RecentFilesState(files: []);
}
