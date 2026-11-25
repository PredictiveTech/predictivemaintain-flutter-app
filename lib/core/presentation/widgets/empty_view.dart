import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;

  const EmptyView(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
