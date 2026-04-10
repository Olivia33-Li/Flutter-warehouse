import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _bgColor       = Color(0xFFF5F3F0);
const _titleColor    = Color(0xFF1A1A2E);
const _mutedNavColor = Color(0xFFB5B5C0);
const _activeNavBg   = Color(0xFFF0EFED);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/skus')) {
      selectedIndex = 0;
    } else if (location.startsWith('/locations')) {
      selectedIndex = 1;
    } else if (location.startsWith('/scanner')) {
      selectedIndex = 2;
    } else if (location.startsWith('/history')) {
      selectedIndex = 3;
    } else if (location.startsWith('/settings')) {
      selectedIndex = 4;
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: child,
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedIndex,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/skus');      break;
            case 1: context.go('/locations'); break;
            case 2: context.go('/scanner');   break;
            case 3: context.go('/history');   break;
            case 4: context.go('/settings');  break;
          }
        },
      ),
    );
  }
}

// ── Custom bottom navigation bar ─────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: _bgColor,
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad > 0 ? bottomPad : 8),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(icon: Icons.grid_view_rounded,       label: 'SKU',  index: 0, selected: selectedIndex == 0, onTap: onTap),
            _NavItem(icon: Icons.location_on_outlined,    label: '位置', index: 1, selected: selectedIndex == 1, onTap: onTap),
            _NavItem(icon: Icons.qr_code_scanner_rounded, label: '扫码', index: 2, selected: selectedIndex == 2, onTap: onTap),
            _NavItem(icon: Icons.history_rounded,         label: '记录', index: 3, selected: selectedIndex == 3, onTap: onTap),
            _NavItem(icon: Icons.settings_outlined,       label: '设置', index: 4, selected: selectedIndex == 4, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _titleColor : _mutedNavColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? _activeNavBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
