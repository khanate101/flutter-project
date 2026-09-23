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
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int sourceTab = 0;
  int mediaTab = 2;

  @override
  Widget build(BuildContext context) {
    final source = sourceTab == 0 ? 'messenger' : 'business';
    final data = ref.watch(whatsappStatusProvider(source));

    return Scaffold(
      appBar: AppBar(
        title: const Text('StatusVault'),
        actions: [
          IconButton(
            tooltip: 'تحديث الحالات',
            onPressed: () => ref.invalidate(whatsappStatusProvider(source)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              onTap: (index) => setState(() => sourceTab = index),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: WhatsAppStatusIcon(), text: 'واتساب ماسنجر'),
                Tab(icon: WhatsAppStatusIcon(), text: 'واتساب بيزنس'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(whatsappStatusProvider(source)),
              child: data.when(
                loading: () => const _Skeleton(),
                error: (_, __) => _ErrorState(
                  onRetry: () => ref.invalidate(whatsappStatusProvider(source)),
                ),
                data: (items) {
                  final filtered = items.where((x) =>
                      mediaTab == 2 ||
                      (mediaTab == 0
                          ? x.type == StatusType.image
                          : x.type == StatusType.video)).toList();

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sourceTab == 0
                                      ? 'حالات واتساب ماسنجر'
                                      : 'حالات واتساب بيزنس',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                items.length.toString(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                label: Text('الصور'),
                                icon: Icon(Icons.image_outlined),
                              ),
                              ButtonSegment(
                                value: 1,
                                label: Text('الفيديوهات'),
                                icon: Icon(Icons.videocam_outlined),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text('الكل'),
                                icon: Icon(Icons.grid_view),
                              ),
                            ],
                            selected: {mediaTab},
                            onSelectionChanged: (s) =>
                                setState(() => mediaTab = s.first),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          child: _EmptyState(
                            sourceTab: sourceTab,
                            isWeb: kIsWeb,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(10),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: .82,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                StatusCard(item: filtered[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppStatusIcon extends StatelessWidget {
  const WhatsAppStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: -5,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    child: Icon(Icons.arrow_downward_rounded, size: 10),
                  ),
                  Positioned(
                    bottom: -1,
                    child: Text(
                      'S',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                ? Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  )
                : MediaImage(item.uri),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(favoritesProvider).toggle(item.id),
                    icon: Icon(
                      ref.watch(favoritesProvider).contains(item.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(statusRepositoryProvider).saveToGallery(item),
                    icon: const Icon(Icons.download, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/viewer', extra: item),
                    icon: Icon(
                      item.isVideo ? Icons.play_arrow : Icons.visibility,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isVideo)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.videocam, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.sourceTab, required this.isWeb});

  final int sourceTab;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final name = sourceTab == 0 ? 'واتساب ماسنجر' : 'واتساب بيزنس';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 70),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على حالات متاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isWeb
                  ? 'الإصدار الويب لا يستطيع الوصول إلى مجلدات واتساب الخاصة في الهاتف.'
                  : 'لم يتم العثور على حالات في مجلد ' + name +
                      '. تأكد من وجود حالات حديثة ومنح التطبيق صلاحية الصور والفيديو.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .82,
        ),
        itemBuilder: (_, __) => Card(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      );
}
