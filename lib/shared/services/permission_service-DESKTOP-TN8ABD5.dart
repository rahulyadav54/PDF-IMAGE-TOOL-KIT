import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_exception.dart';

final permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());

/// Requests permissions only when a feature needs them.
class PermissionService {
  Future<void> requestCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      throw const PermissionDeniedException('Camera');
    }

    final result = await Permission.camera.request();
    if (!result.isGranted) {
      throw const PermissionDeniedException('Camera');
    }
  }
}
