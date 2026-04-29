import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/force_change_password_screen.dart';
import '../screens/settings/password_reset_requests_screen.dart';
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
import '../screens/inventory/inventory_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/skus',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register' || path == '/forgot-password';
      final isForceChangePwd = path == '/force-change-password';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return user.mustChangePassword ? '/force-change-password' : '/skus';
      }
      if (isLoggedIn && user.mustChangePassword && !isForceChangePwd) {
        return '/force-change-password';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/force-change-password', builder: (_, __) => const ForceChangePasswordScreen()),
      GoRoute(path: '/password-reset-requests', builder: (_, __) => const PasswordResetRequestsScreen()),

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
      GoRoute(
        path: '/inventory/history',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InventoryHistoryScreen(
            skuCode: extra?['skuCode'] ?? '',
            skuId: extra?['skuId'],
            locationId: extra?['locationId'] ?? '',
            locationCode: extra?['locationCode'] ?? '',
          );
        },
      ),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/skus', builder: (_, __) => const SkusScreen()),
          GoRoute(path: '/locations', builder: (_, __) => const LocationsScreen()),
          GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
          GoRoute(
            path: '/history',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return HistoryScreen(
                initialLocationCode: extra?['locationCode'] as String?,
                initialSkuCode: extra?['skuCode'] as String?,
              );
            },
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
