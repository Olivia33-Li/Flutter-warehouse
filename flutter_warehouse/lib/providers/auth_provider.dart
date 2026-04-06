import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((_) => AuthService());

final currentUserProvider = StateNotifierProvider<UserNotifier, User?>(
  (ref) => UserNotifier(ref.read(authServiceProvider)),
);

final recentAccountsProvider = StateNotifierProvider<RecentAccountsNotifier, List<RecentAccount>>(
  (ref) => RecentAccountsNotifier(ref.read(authServiceProvider)),
);

// ─── UserNotifier ──────────────────────────────────────────────────────────────

class UserNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _authService.getCurrentUser();
  }

  Future<void> login({required String username, required String password}) async {
    state = await _authService.login(username: username, password: password);
  }

  Future<void> register({
    required String username,
    required String name,
    required String password,
  }) async {
    state = await _authService.register(username: username, name: name, password: password);
  }

  void updateName(String name) {
    if (state != null) state = state!.copyWith(name: name);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

// ─── RecentAccountsNotifier ───────────────────────────────────────────────────

class RecentAccountsNotifier extends StateNotifier<List<RecentAccount>> {
  final AuthService _authService;

  RecentAccountsNotifier(this._authService) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _authService.getRecentAccounts();
  }

  Future<void> remove(String username) async {
    await _authService.removeRecentAccount(username);
    await _load();
  }

  Future<void> clearAll() async {
    await _authService.clearRecentAccounts();
    state = [];
  }

  Future<void> refresh() async => _load();
}
