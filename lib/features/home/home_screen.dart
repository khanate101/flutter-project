import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/status_item.dart';
import '../../providers/status_providers.dart';
import '../../repositories/favorites_repository.dart';
import '../../core/widgets/media_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int tab = 2;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(statusListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('StatusVault'), actions: [IconButton(tooltip: kIsWeb ? 'اختيار صور وفيديوهات من الجهاز' : 'اختيار مجلد حالات واتساب', onPressed: () async { final ok = await ref.read(statusRepositoryProvider).pickWhatsAppStatusFolder(); if (ok) ref.invalidate(statusListProvider); }, icon: const Icon(Icons.folder_open))]),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(statusListProvider),
        child: data.when(
          loading: () => const _Skeleton(),
          error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(statusListProvider)),
          data: (items) {
            final filtered = items.where((x) => tab == 2 || (tab == 0 ? x.type == StatusType.image : x.type == StatusType.video)).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text('حالات واتساب المتاحة', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('الصور'), icon: Icon(Icons.image_outlined)),
                        ButtonSegment(value: 1, label: Text('الفيديوهات'), icon: Icon(Icons.videocam_outlined)),
                        ButtonSegment(value: 2, label: Text('الكل'), icon: Icon(Icons.grid_view)),
                      ],
                      selected: {tab},
                      onSelectionChanged: (s) => setState(() => tab = s.first),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(10),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .82,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => StatusCard(item: filtered[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key, required this.item});
  final StatusItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/viewer', extra: item),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.isVideo
                ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white)))
                : MediaImage(item.uri),
            Positioned(
              left: 8, right: 8, bottom: 8,
              child: Row(
                children: [
                  Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  IconButton(
                    onPressed: () => ref.read(favoritesProvider).toggle(item.id),
                    icon: Icon(ref.watch(favoritesProvider).contains(item.id) ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                  IconButton(
                    onPressed: () => ref.read(statusRepositoryProvider).saveToGallery(item),
                    icon: const Icon(Icons.download, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                  IconButton(
                    onPressed: () => context.push('/viewer', extra: item),
                    icon: Icon(item.isVideo ? Icons.play_arrow : Icons.visibility, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                ],
              ),
            ),
            if (item.isVideo) const Positioned(top: 8, right: 8, child: Icon(Icons.videocam, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(30),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.photo_library_outlined, size: 70),
      SizedBox(height: 16),
      Text('لم يتم العثور على حالات متاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text(kIsWeb ? 'اضغط زر المجلد أعلى الصفحة لاختيار الصور والفيديوهات من جهازك. يعمل الإصدار الويب داخل صلاحيات المتصفح فقط.' : 'اضغط زر المجلد أعلى الصفحة واختر مجلد حالات WhatsApp الذي يسمح Android بالوصول إليه. التطبيق لا يتجاوز حماية النظام.', textAlign: TextAlign.center),
    ]),
  ));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Center(child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')));
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(12), itemCount: 8,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .82),
    itemBuilder: (_, __) => Card(child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
  );
}
