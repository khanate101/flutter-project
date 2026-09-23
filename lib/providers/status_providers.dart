import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/status_item.dart';
import '../repositories/status_repository.dart';

final statusRepositoryProvider = Provider((ref) => StatusRepository());

final statusListProvider = FutureProvider.autoDispose<List<StatusItem>>((ref) async {
  return ref.read(statusRepositoryProvider).scanAvailableMedia();
});

final whatsappStatusProvider =
    FutureProvider.autoDispose.family<List<StatusItem>, String>((ref, type) async {
  return ref.read(statusRepositoryProvider).scanWhatsAppStatus(type);
});
