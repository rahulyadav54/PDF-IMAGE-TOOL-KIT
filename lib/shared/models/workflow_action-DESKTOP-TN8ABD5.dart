import 'package:flutter/material.dart';

/// Next-step action shown on result screens after a tool completes.
class WorkflowAction {
  const WorkflowAction({
    required this.label,
    required this.icon,
    required this.route,
    this.passOutputPath = true,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool passOutputPath;
}
