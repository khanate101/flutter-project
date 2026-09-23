import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.create();
  runApp(
    ProviderScope(
      overrides: [settingsServiceProvider.overrideWith((ref) => settings)],
      child: const StatusVaultApp(),
    ),
  );
}
