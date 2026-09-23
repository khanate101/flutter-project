import 'package:path/path.dart' as p;

class FileUtils {
  static bool isVideo(String path) =>
      ['mp4', 'mkv', 'webm', 'mov', '3gp', 'avi'].contains(_extension(path));

  static bool isImage(String path) =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'].contains(_extension(path));

  static String _extension(String path) =>
      p.extension(Uri.tryParse(path)?.path ?? path).replaceFirst('.', '').toLowerCase();

  static String mediaKey(String path, int size, int modifiedMs) =>
      '$path|$size|$modifiedMs';
}
