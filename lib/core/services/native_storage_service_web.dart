import 'dart:html' as html;

class NativeStorageService {
  static final List<Map<String, dynamic>> _selected = [];
  static final List<Map<String, dynamic>> _saved = [];

  Future<bool> pickStatusFolder() async {
    final input = html.FileUploadInputElement()
      ..multiple = true
      ..accept = 'image/*,video/*';
    input.click();
    await input.onChange.first;
    final files = input.files ?? const <html.File>[];
    if (files.isEmpty) return false;

    for (final file in files) {
      final type = file.type.toLowerCase();
      if (!type.startsWith('image/') && !type.startsWith('video/')) continue;
      final url = html.Url.createObjectUrl(file);
      _selected.removeWhere((item) => item['name'] == file.name);
      _selected.add({
        'path': url,
        'name': file.name,
        'mime': type,
        'modified': file.lastModified,
        'size': file.size,
      });
    }
    return _selected.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> scanStatusFolder() async =>
      List<Map<String, dynamic>>.from(_selected);

  Future<bool> saveMedia(String path, String title) async {
    final item = _find(path);
    if (item == null) return false;
    final anchor = html.AnchorElement(href: path)
      ..download = title.isEmpty ? item['name'] as String : title
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    _saved.removeWhere((x) => x['path'] == path);
    _saved.add(Map<String, dynamic>.from(item));
    return true;
  }

  Future<List<Map<String, dynamic>>> listSavedMedia() async =>
      List<Map<String, dynamic>>.from(_saved);

  Future<bool> deleteSavedMedia(String path) async {
    final before = _saved.length;
    _saved.removeWhere((x) => x['path'] == path);
    return _saved.length != before;
  }

  Map<String, dynamic>? _find(String path) {
    for (final item in _selected) {
      if (item['path'] == path) return item;
    }
    for (final item in _saved) {
      if (item['path'] == path) return item;
    }
    return null;
  }
}
