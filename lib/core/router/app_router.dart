import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/status_viewer/status_viewer_screen.dart';
import '../../models/status_item.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/viewer',
      builder: (context, state) {
        final item = state.extra! as StatusItem;
        return StatusViewerScreen(item: item);
      },
    ),
  ],
);

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = switch (location) {
      '/saved' => 1,
      '/favorites' => 2,
      '/settings' => 3,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(['/home','/saved','/favorites','/settings'][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'المحفوظات'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
