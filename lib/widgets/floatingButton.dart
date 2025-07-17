import 'package:flutter/material.dart';

class FloatingWidgetButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const FloatingWidgetButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      enableFeedback: true,
      tooltip: tooltip,
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      child: Icon(icon)
    );
  }
}