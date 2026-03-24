import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/skus')) {
      selectedIndex = 0;
    } else if (location.startsWith('/locations')) selectedIndex = 1;
    else if (location.startsWith('/scanner')) selectedIndex = 2;
    else if (location.startsWith('/history')) selectedIndex = 3;
    else if (location.startsWith('/settings')) selectedIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/skus'); break;
            case 1: context.go('/locations'); break;
            case 2: context.go('/scanner'); break;
            case 3: context.go('/history'); break;
            case 4: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'SKU'),
          NavigationDestination(icon: Icon(Icons.location_on), label: '位置'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: '扫码'),
          NavigationDestination(icon: Icon(Icons.history), label: '记录'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
