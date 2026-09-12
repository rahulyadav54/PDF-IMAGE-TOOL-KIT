import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

class VaultFileEntry {
  const VaultFileEntry({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.addedAt,
  });

  final String id;
  final String originalName;
  final String storedName;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'storedName': storedName,
        'addedAt': addedAt.toIso8601String(),
      };

  factory VaultFileEntry.fromJson(Map<String, dynamic> json) => VaultFileEntry(
        id: json['id'] as String,
        originalName: json['originalName'] as String,
        storedName: json['storedName'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class VaultService {
  Future<Directory> _vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'secure_vault'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.vaultPinHashKey) != null;
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw Exception('PIN must be at least 4 digits.');
    }
    final hash = sha256.convert(utf8.encode(pin)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.vaultPinHashKey, hash);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.vaultPinHashKey);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return stored == hash;
  }

  Future<List<VaultFileEntry>> listFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.vaultFilesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VaultFileEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveList(List<VaultFileEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.vaultFilesKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Encrypter _encrypter(String pin) {
    final keyBytes = sha256.convert(utf8.encode('vault:$pin')).bytes;
    return Encrypter(AES(Key(Uint8List.fromList(keyBytes))));
  }

  Future<void> addFile({
    required String sourcePath,
    required String pin,
  }) async {
    if (!await verifyPin(pin)) {
      throw Exception('Incorrect PIN.');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('File not found.');
    }

    final bytes = await source.readAsBytes();
    final enc = _encrypter(pin);
    final iv = IV.fromSecureRandom(16);
    final encrypted = enc.encryptBytes(bytes, iv: iv);
    final storedName = '${DateTime.now().millisecondsSinceEpoch}.vault';
    final dir = await _vaultDir();
    final out = File(p.join(dir.path, storedName));
    await out.writeAsBytes(iv.bytes + encrypted.bytes);

    final entries = await listFiles();
    entries.insert(
      0,
      VaultFileEntry(
        id: storedName,
        originalName: p.basename(sourcePath),
        storedName: storedName,
        addedAt: DateTime.now(),
      ),
    );
    await _saveList(entries);
  }

  Future<String> exportFile({
    required VaultFileEntry entry,
    required String pin,
  }) async {
    if (!await verifyPin(pin)) {
      throw Exception('Incorrect PIN.');
    }

    final dir = await _vaultDir();
    final file = File(p.join(dir.path, entry.storedName));
    if (!await file.exists()) {
      throw Exception('Vault file missing.');
    }

    final raw = await file.readAsBytes();
    final iv = IV(raw.sublist(0, 16));
    final encrypted = Encrypted(raw.sublist(16));
    final decrypted = _encrypter(pin).decryptBytes(encrypted, iv: iv);

    final outputDir = await getTemporaryDirectory();
    final outPath = p.join(outputDir.path, entry.originalName);
    await File(outPath).writeAsBytes(decrypted);
    return outPath;
  }

  Future<void> removeFile(VaultFileEntry entry) async {
    final dir = await _vaultDir();
    final file = File(p.join(dir.path, entry.storedName));
    if (await file.exists()) await file.delete();
    final entries = await listFiles();
    entries.removeWhere((e) => e.id == entry.id);
    await _saveList(entries);
  }
}
