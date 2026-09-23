import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/status_item.dart';
import '../../repositories/status_repository.dart';
import '../../repositories/favorites_repository.dart';
import '../../core/services/media_share.dart';
import '../../core/widgets/media_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  const StatusViewerScreen({super.key, required this.item});
  final StatusItem item;
  @override ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> {
  VideoPlayerController? _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _controller = VideoPlayerController.file(File(widget.item.uri))
        ..initialize().then((_) { if (mounted) setState(() {}); });
    }
  }

  @override void dispose() { _controller?.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _busy = true);
    final saved = await StatusRepository().saveToGallery(widget.item);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'تم حفظ الحالة بنجاح ✓' : 'تعذر حفظ الملف')));
  }

  Future<void> _share() async {
    final ok = await shareMedia(widget.item.uri, text: 'StatusVault');
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر مشاركة الملف')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: Text(widget.item.title),
        actions: [
          IconButton(onPressed: () => ref.read(favoritesProvider).toggle(widget.item.id), icon: Icon(ref.watch(favoritesProvider).contains(widget.item.id) ? Icons.favorite : Icons.favorite_border)),
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
          IconButton(onPressed: _busy ? null : _save, icon: _busy ? const CircularProgressIndicator() : const Icon(Icons.download)),
        ],
      ),
      body: Center(child: widget.item.isVideo ? _video() : InteractiveViewer(minScale: .7, maxScale: 5, child: MediaImage(widget.item.uri, fit: BoxFit.contain))),
    );
  }

  Widget _video() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const CircularProgressIndicator(color: Colors.white);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
      VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.all(16), colors: const VideoProgressColors(playedColor: Colors.white)),
      IconButton.filled(onPressed: () => setState(() => c.value.isPlaying ? c.pause() : c.play()), icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow)),
    ]);
  }
}
