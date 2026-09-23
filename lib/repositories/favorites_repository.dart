import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider = ChangeNotifierProvider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository() {
    _load();
  }

  final Set<String> _ids = <String>{};

  bool contains(String id) => _ids.contains(id);
  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList('favorites') ?? const <String>[]);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _ids.toList(growable: false));
    notifyListeners();
  }
}
