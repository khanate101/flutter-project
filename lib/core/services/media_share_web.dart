import 'dart:html' as html;
Future<bool> shareMedia(String uri, {String? text}) async {
  try {
    final anchor = html.AnchorElement(href: uri)
      ..download = _fileName(uri)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) { return false; }
}
String _fileName(String uri) {
  final path = Uri.tryParse(uri)?.path ?? uri;
  final name = path.split('/').last;
  return name.isEmpty ? 'StatusVault-media' : name;
}
