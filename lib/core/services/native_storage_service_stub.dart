class NativeStorageService {
  Future<bool> pickStatusFolder() async => false;
  Future<List<Map<String, dynamic>>> scanStatusFolder() async => const [];
  Future<List<Map<String, dynamic>>> scanWhatsAppStatus(String type) async => const [];
  Future<bool> saveMedia(String path, String title) async => false;
  Future<List<Map<String, dynamic>>> listSavedMedia() async => const [];
  Future<bool> deleteSavedMedia(String path) async => false;
}
