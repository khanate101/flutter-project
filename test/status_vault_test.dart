import 'package:flutter_test/flutter_test.dart';
import 'package:status_vault/core/utils/file_utils.dart';

void main() {
  test('duplicate keys are stable for same file metadata', () {
    final a = FileUtils.mediaKey('/a/status.jpg', 100, 2000);
    final b = FileUtils.mediaKey('/a/status.jpg', 100, 2000);
    expect(a, b);
  });

  test('extensions are classified', () {
    expect(FileUtils.isVideo('clip.MP4'), isTrue);
    expect(FileUtils.isImage('photo.JPG'), isTrue);
  });
}
