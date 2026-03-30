import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/skus/skus_screen.dart';
import '../screens/skus/sku_detail_screen.dart';
import '../screens/skus/sku_form_screen.dart';
import '../screens/locations/locations_screen.dart';
import '../screens/locations/location_detail_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/inventory/inventory_add_screen.dart';
import '../widgets/main_shell.dart';
import '../screens/import/import_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/skus',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/skus';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // 详情页放在 ShellRoute 外，返回键正确回到上一页
      GoRoute(
        path: '/skus/new',
        builder: (_, state) => SkuFormScreen(initial: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/skus/:id',
        builder: (_, state) => SkuDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/locations/:id',
        builder: (_, state) => LocationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/inventory/add',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InventoryAddScreen(
            initialSkuId: extra?['skuId'],
            initialLocationId: extra?['locationId'],
          );
        },
      ),
      GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/skus', builder: (_, __) => const SkusScreen()),
          GoRoute(path: '/locations', builder: (_, __) => const LocationsScreen()),
          GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
