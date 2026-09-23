enum StatusType { image, video }

class StatusItem {
  const StatusItem({
    required this.id,
    required this.uri,
    required this.title,
    required this.type,
    required this.modified,
    this.duration,
    this.isSaved = false,
    this.isFavorite = false,
  });

  final String id;
  final String uri;
  final String title;
  final StatusType type;
  final DateTime modified;
  final Duration? duration;
  final bool isSaved;
  final bool isFavorite;

  bool get isVideo => type == StatusType.video;
}
