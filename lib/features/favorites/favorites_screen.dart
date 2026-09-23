import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/favorites_repository.dart';
import '../../core/widgets/media_image.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider);
    final ids = fav.ids.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: ids.isEmpty
          ? const Center(child: Text('لا توجد مفضلات بعد'))
          : ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                final path = id.contains('|') ? id.split('|').first : id;
                return ListTile(
                  leading: SizedBox(width: 52, height: 52, child: MediaImage(path)),
                  title: Text(path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: () => ref.read(favoritesProvider).toggle(id),
                  ),
                );
              },
            ),
    );
  }
}
