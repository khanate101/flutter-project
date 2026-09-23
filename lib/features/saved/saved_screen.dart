import 'package:flutter/material.dart';
import '../../core/services/native_storage_service.dart';
import '../../core/services/media_share.dart';
import '../../core/utils/file_utils.dart';
import '../../core/widgets/media_image.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final search = TextEditingController();
  final storage = NativeStorageService();
  int tab = 0;
  List<Map<String, dynamic>> files = [];

  @override
  void initState() {
    super.initState();
    _load();
    search.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final list = await storage.listSavedMedia();
    if (mounted) setState(() => files = list);
  }

  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = search.text.toLowerCase();
    final shown = files.where((item) {
      final path = item['path'] as String? ?? '';
      final name = item['name'] as String? ?? path;
      final isVideo = item['isVideo'] == true || FileUtils.isVideo(path);
      return (tab == 0 || (tab == 1 && !isVideo) || (tab == 2 && isVideo)) &&
          name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المحفوظات')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search), hintText: 'بحث بالاسم أو النوع',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('الكل')),
              ButtonSegment(value: 1, label: Text('الصور')),
              ButtonSegment(value: 2, label: Text('الفيديوهات')),
            ],
            selected: {tab},
            onSelectionChanged: (s) => setState(() => tab = s.first),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('لا توجد ملفات محفوظة'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final item = shown[index];
                    final path = item['path'] as String;
                    final isVideo = item['isVideo'] == true || FileUtils.isVideo(path);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(fit: StackFit.expand, children: [
                        isVideo
                            ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle_outline, size: 60, color: Colors.white)))
                            : MediaImage(path),
                        Positioned(
                          bottom: 4, left: 4, right: 4,
                          child: Row(children: [
                            IconButton(
                              onPressed: () => shareMedia(path, text: 'StatusVault'),
                              icon: const Icon(Icons.share, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () async {
                                if (await storage.deleteSavedMedia(path)) await _load();
                              },
                              icon: const Icon(Icons.delete, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
