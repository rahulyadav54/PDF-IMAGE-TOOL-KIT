import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../shared/models/tool_type.dart';

final homeWidgetServiceProvider =
    Provider<HomeWidgetService>((ref) => HomeWidgetService());

class HomeWidgetService {
  static const appGroupId = 'com.pdftoolbox.pdf_image_toolbox.widget';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>('scan_route', ToolType.scanToPdf.route);
      await HomeWidget.saveWidgetData<String>('compress_route', ToolType.compressPdf.route);
      await HomeWidget.saveWidgetData<String>('files_route', '/files');
      await HomeWidget.updateWidget(
        name: 'HomeWidgetProvider',
        androidName: 'HomeWidgetProvider',
      );
    } catch (_) {}
  }

  Future<String?> getLaunchedRoute() async {
    try {
      return await HomeWidget.getWidgetData<String>('launched_route');
    } catch (_) {
      return null;
    }
  }
}
