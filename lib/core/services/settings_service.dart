import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  throw StateError('SettingsService must be overridden in main()');
});

class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsService> create() async {
    return SettingsService(await SharedPreferences.getInstance());
  }

  ThemeMode get themeMode {
    switch (_prefs.getString('themeMode')) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale => Locale(_prefs.getString('locale') ?? 'ar');
  bool get autoplay => _prefs.getBool('autoplay') ?? false;
  bool get autoSave => _prefs.getBool('autoSave') ?? false;
  bool get onboarded => _prefs.getBool('onboarded') ?? false;

  Future<void> setThemeMode(ThemeMode value) async {
    final name = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _prefs.setString('themeMode', name);
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    await _prefs.setString('locale', value.languageCode);
    notifyListeners();
  }

  Future<void> setAutoplay(bool value) async {
    await _prefs.setBool('autoplay', value);
    notifyListeners();
  }

  Future<void> setAutoSave(bool value) async {
    await _prefs.setBool('autoSave', value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboarded', true);
    notifyListeners();
  }
}
