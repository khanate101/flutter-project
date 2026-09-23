import 'dart:io';
import 'package:flutter/services.dart';

class NativeStorageService {
  static const _channel = MethodChannel('statusvault/storage');

  Future<bool> pickStatusFolder() async =>
      await _channel.invokeMethod<bool>('pickStatusFolder') ?? false;

  Future<List<Map<String, dynamic>>> scanStatusFolder() async {
    final raw = await _channel.invokeListMethod<dynamic>('scanStatusFolder') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<bool> pickWhatsAppStatusFolder(String type) async =>
      await _channel.invokeMethod<bool>('pickWhatsAppStatusFolder', {'type': type}) ?? false;

  Future<List<Map<String, dynamic>>> scanWhatsAppStatus(String type) async {
    final raw = await _channel.invokeListMethod<dynamic>(
          'scanWhatsAppStatus',
          {'type': type},
        ) ??
        [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<bool> saveMedia(String path, String title) async =>
      await _channel.invokeMethod<bool>('saveMedia', {'path': path, 'title': title}) ?? false;

  Future<List<Map<String, dynamic>>> listSavedMedia() async {
    final root = Directory('/storage/emulated/0/Pictures/StatusVault');
    if (!await root.exists()) return const [];
    final result = <Map<String, dynamic>>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      final path = entity.path;
      final lower = path.toLowerCase();
      final isVideo = lower.endsWith('.mp4') || lower.endsWith('.3gp') ||
          lower.endsWith('.webm') || lower.endsWith('.mkv') || lower.endsWith('.mov');
      final isImage = lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
          lower.endsWith('.png') || lower.endsWith('.webp') || lower.endsWith('.gif') ||
          lower.endsWith('.heic') || lower.endsWith('.heif');
      if (!isVideo && !isImage) continue;
      result.add({
        'path': path,
        'name': path.split(Platform.pathSeparator).last,
        'isVideo': isVideo,
        'modified': stat.modified.millisecondsSinceEpoch,
        'size': stat.size,
      });
    }
    result.sort((a, b) => (b['modified'] as int).compareTo(a['modified'] as int));
    return result;
  }

  Future<bool> deleteSavedMedia(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
