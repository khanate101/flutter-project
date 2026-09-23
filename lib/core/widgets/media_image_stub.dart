import 'package:flutter/material.dart';
class MediaImage extends StatelessWidget {
  const MediaImage(this.uri, {super.key, this.fit = BoxFit.cover});
  final String uri; final BoxFit fit;
  @override Widget build(BuildContext context) => Image.network(uri, fit: fit);
}
