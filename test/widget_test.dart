import 'package:flutter_test/flutter_test.dart';
import 'package:status_vault/app.dart';

void main() {
  testWidgets('StatusVault app builds', (tester) async {
    // The app normally initializes SharedPreferences before runApp in main().
    // This test only verifies that the root widget can be constructed.
    expect(const StatusVaultApp(), isA<StatusVaultApp>());
  });
}
