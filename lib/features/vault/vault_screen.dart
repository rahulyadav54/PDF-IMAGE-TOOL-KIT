import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/vault_service.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _pinController = TextEditingController();
  bool _unlocked = false;
  bool _isSettingPin = false;
  List<VaultFileEntry> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final vault = ref.read(vaultServiceProvider);
    final hasPin = await vault.hasPin();
    setState(() {
      _isSettingPin = !hasPin;
    });
  }

  Future<void> _unlock() async {
    final vault = ref.read(vaultServiceProvider);
    final ok = await vault.verifyPin(_pinController.text);
    if (!ok) {
      setState(() => _error = 'Incorrect PIN.');
      return;
    }
    final files = await vault.listFiles();
    setState(() {
      _unlocked = true;
      _files = files;
      _error = null;
    });
  }

  Future<void> _setPin() async {
    if (_pinController.text.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    await ref.read(vaultServiceProvider).setPin(_pinController.text);
    setState(() {
      _isSettingPin = false;
      _unlocked = true;
      _files = [];
      _error = null;
    });
  }

  Future<void> _addFile() async {
    final path = await ref.read(fileServiceProvider).pickFile();
    if (path == null) return;
    try {
      await ref.read(vaultServiceProvider).addFile(
            sourcePath: path,
            pin: _pinController.text,
          );
      _files = await ref.read(vaultServiceProvider).listFiles();
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openFile(VaultFileEntry entry) async {
    try {
      final path = await ref.read(vaultServiceProvider).exportFile(
            entry: entry,
            pin: _pinController.text,
          );
      await ref.read(fileActionsServiceProvider).openFile(path);
    } catch (e) {
      setState(() => _error = 'Could not open file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Secure Vault')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSettingPin ? 'Create vault PIN' : 'Enter vault PIN',
                  style: AppTypography.sectionTitle(context),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSettingPin ? _setPin : _unlock,
                  child: Text(_isSettingPin ? 'Create Vault' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        actions: [
          IconButton(
            onPressed: _addFile,
            icon: const Icon(Icons.add_outlined),
            tooltip: 'Add file',
          ),
        ],
      ),
      body: _files.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 48, color: scheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text('No files in vault', style: AppTypography.cardTitle(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add sensitive PDFs and images. Files are encrypted on your device.',
                      textAlign: TextAlign.center,
                      style: AppTypography.cardSubtitle(context),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              itemCount: _files.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = _files[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  tileColor: scheme.surfaceContainerLow,
                  leading: const Icon(Icons.lock_outline),
                  title: Text(entry.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(entry.addedAt.toLocal().toString().split('.').first),
                  onTap: () => _openFile(entry),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(vaultServiceProvider).removeFile(entry);
                      _files = await ref.read(vaultServiceProvider).listFiles();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
