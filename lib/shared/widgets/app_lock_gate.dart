import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_lock_service.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _unlocked = false;
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    final enabled = ref.read(appLockEnabledProvider);
    if (!enabled) {
      setState(() => _unlocked = true);
      return;
    }
    if (_checking || _unlocked) return;
    setState(() => _checking = true);
    final ok = await ref.read(appLockServiceProvider).authenticate();
    if (mounted) {
      setState(() {
        _unlocked = ok;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockEnabledProvider);
    if (!enabled || _unlocked) return widget.child;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 56),
              const SizedBox(height: 16),
              const Text('App locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Authenticate to continue'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _checking ? null : _maybeLock,
                child: Text(_checking ? 'Checking...' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
