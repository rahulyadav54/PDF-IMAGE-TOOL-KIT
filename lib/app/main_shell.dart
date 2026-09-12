import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_exit_guard.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/files') || location.startsWith('/documents')) {
      return 1;
    }
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/tools-hub')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFromLocation(location);
    final scheme = Theme.of(context).colorScheme;

    return AppExitGuard(
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 4,
              ),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    selected: selected == 0,
                    onTap: () => context.go('/'),
                  ),
                  _NavItem(
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder_rounded,
                    label: 'Files',
                    selected: selected == 1,
                    onTap: () => context.go('/files'),
                  ),
                  _NavItem(
                    icon: Icons.document_scanner_outlined,
                    selectedIcon: Icons.document_scanner_rounded,
                    label: 'Scan',
                    selected: selected == 2,
                    emphasized: true,
                    onTap: () => context.push('/scan-to-pdf'),
                  ),
                  _NavItem(
                    icon: Icons.apps_outlined,
                    selectedIcon: Icons.apps_rounded,
                    label: 'Tools',
                    selected: selected == 3,
                    onTap: () => context.go('/tools-hub'),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: selected == 4,
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = selected || emphasized;
    final color = selected
        ? AppColors.electricBlue
        : emphasized
            ? AppColors.electricBlue
            : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emphasized)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.electricBlue
                        : AppColors.electricBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: selected ? Colors.white : AppColors.electricBlue,
                  ),
                )
              else
                Icon(
                  selected ? selectedIcon : icon,
                  size: 24,
                  color: color,
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
