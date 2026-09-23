import 'package:share_plus/share_plus.dart';
Future<bool> shareMedia(String uri, {String? text}) async {
  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(uri)], text: text));
    return true;
  } catch (_) { return false; }
}
