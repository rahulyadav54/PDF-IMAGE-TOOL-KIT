import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService());

final appLockEnabledProvider =
    StateNotifierProvider<AppLockNotifier, bool>((ref) => AppLockNotifier());

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.appLockEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.appLockEnabledKey, enabled);
  }
}

class AppLockService {
  final _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock DocForge',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
