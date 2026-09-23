import 'package:flutter/material.dart';
class MediaImage extends StatelessWidget {
  const MediaImage(this.uri, {super.key, this.fit = BoxFit.cover});
  final String uri; final BoxFit fit;
  @override Widget build(BuildContext context) => Image.network(uri, fit: fit,
    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 40)));
}
