import '../models/status_item.dart';
import '../core/services/native_storage_service.dart';

class StatusRepository {
  final NativeStorageService nativeStorage = NativeStorageService();

  Future<bool> pickWhatsAppStatusFolder(String type) => nativeStorage.pickWhatsAppStatusFolder(type);

  Future<List<StatusItem>> scanWhatsAppStatus(String type) async =>
      _map(await nativeStorage.scanWhatsAppStatus(type));

  Future<List<StatusItem>> scanAvailableMedia() async =>
      _map(await nativeStorage.scanStatusFolder());

  Future<bool> saveToGallery(StatusItem item) =>
      nativeStorage.saveMedia(item.uri, item.title);

  List<StatusItem> _map(List<Map<String, dynamic>> items) => items.map((e) {
    final path = e['path'] as String;
    final mime = e['mime'] as String? ?? '';
    final isVideo = e['isVideo'] == true || mime.startsWith('video/');
    return StatusItem(
      id: path + '|' + (e['size'] ?? 0).toString() + '|' + (e['modified'] ?? 0).toString(),
      uri: path,
      title: e['name'] as String? ?? path,
      type: isVideo ? StatusType.video : StatusType.image,
      modified: DateTime.fromMillisecondsSinceEpoch((e['modified'] as num?)?.toInt() ?? 0),
    );
  }).toList();
}
