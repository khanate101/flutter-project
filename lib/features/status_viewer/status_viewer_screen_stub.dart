import 'package:flutter/material.dart';
import '../../models/status_item.dart';
class StatusViewerScreen extends StatelessWidget {
  const StatusViewerScreen({super.key, required this.item});
  final StatusItem item;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(item.title)), body: Center(child: Text(item.uri)));
}
