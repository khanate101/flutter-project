import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/native_storage_service.dart';
import '../core/utils/file_utils.dart';
import '../models/status_item.dart';

class StatusRepository {
  final NativeStorageService nativeStorage = NativeStorageService();

  Future<bool> isAllFilesAccessGranted() => nativeStorage.isAllFilesAccessGranted();

  Future<bool> openAllFilesAccessSettings() => nativeStorage.openAllFilesAccessSettings();

  Future<bool> pickWhatsAppStatusFolder(String type) =>
      nativeStorage.pickWhatsAppStatusFolder(type);

  Future<List<StatusItem>> scanWhatsAppStatus(String type) async {
    await Permission.storage.request();
    await Permission.photos.request();
    await Permission.videos.request();
    final selected = await nativeStorage.scanWhatsAppStatus(type);
    return selected.map((e) {
      final path = e['path'] as String;
      final mime = e['mime'] as String? ?? '';
      final modified = (e['modified'] as num?)?.toInt() ?? 0;
      final size = (e['size'] as num?)?.toInt() ?? File(path).lengthSync();
      return StatusItem(
        id: FileUtils.mediaKey(path, size, modified),
        uri: path,
        title: e['name'] as String? ?? path.split(Platform.pathSeparator).last,
        type: mime.startsWith('video/') || e['isVideo'] == true
            ? StatusType.video
            : StatusType.image,
        modified: DateTime.fromMillisecondsSinceEpoch(modified),
      );
    }).toList();
  }

  Future<List<StatusItem>> scanAvailableMedia() async {
    final selected = await nativeStorage.scanStatusFolder();
    if (selected.isNotEmpty) {
      return selected.map((e) {
        final path = e['path'] as String;
        final mime = e['mime'] as String? ?? '';
        final modified = (e['modified'] as num?)?.toInt() ?? 0;
        final size = (e['size'] as num?)?.toInt() ?? File(path).lengthSync();
        return StatusItem(
          id: FileUtils.mediaKey(path, size, modified),
          uri: path,
          title: e['name'] as String? ?? path.split(Platform.pathSeparator).last,
          type: mime.startsWith('video/') ? StatusType.video : StatusType.image,
          modified: DateTime.fromMillisecondsSinceEpoch(modified),
        );
      }).toList();
    }
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return [];
    final albums = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true);
    if (albums.isEmpty) return [];
    final assets = await albums.first.getAssetListPaged(page: 0, size: 300);
    final result = <StatusItem>[];
    for (final asset in assets) {
      if (asset.type != AssetType.image && asset.type != AssetType.video) continue;
      final file = await asset.file;
      if (file == null) continue;
      result.add(StatusItem(
        id: asset.id,
        uri: file.path,
        title: asset.title ?? file.path.split(Platform.pathSeparator).last,
        type: asset.type == AssetType.video ? StatusType.video : StatusType.image,
        modified: asset.modifiedDateTime,
        duration: asset.type == AssetType.video ? Duration(seconds: asset.duration) : null,
      ));
    }
    return result;
  }

  Future<bool> saveToGallery(StatusItem item) =>
      nativeStorage.saveMedia(item.uri, item.title);
}
