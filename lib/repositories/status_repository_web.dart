import '../core/services/native_storage_service.dart';
import '../models/status_item.dart';

class StatusRepository {
  final NativeStorageService nativeStorage = NativeStorageService();

  Future<bool> pickWhatsAppStatusFolder() => nativeStorage.pickStatusFolder();

  Future<List<StatusItem>> scanAvailableMedia() async {
    final selected = await nativeStorage.scanStatusFolder();
    return selected.map((e) {
      final path = e['path'] as String;
      final mime = e['mime'] as String? ?? '';
      final modified = (e['modified'] as num?)?.toInt() ?? 0;
      final isVideo = e['isVideo'] == true || mime.startsWith('video/');
      return StatusItem(
        id: '$path|${e['size'] ?? 0}|$modified',
        uri: path,
        title: e['name'] as String? ?? path,
        type: isVideo ? StatusType.video : StatusType.image,
        modified: DateTime.fromMillisecondsSinceEpoch(modified),
      );
    }).toList();
  }

  Future<bool> saveToGallery(StatusItem item) =>
      nativeStorage.saveMedia(item.uri, item.title);
}
