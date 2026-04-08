import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(currentUserProvider.notifier).login(
        username: username,
        password: password,
        rememberMe: _rememberMe,
      );
      // Refresh recent accounts after successful login
      await ref.read(recentAccountsProvider.notifier).refresh();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? '登录失败，请检查网络'));
    } catch (e) {
      setState(() => _error = '登录失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillAccount(RecentAccount account) {
    setState(() {
      _usernameCtrl.text = account.username;
      _passwordCtrl.clear();
      _error = null;
    });
    // Focus password field
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    final recentAccounts = ref.watch(recentAccountsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warehouse, size: 72, color: Colors.blue),
                const SizedBox(height: 12),
                Text('仓库管理系统',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 32),

                // ── Recent accounts ──────────────────────────────────────────
                if (recentAccounts.isNotEmpty) ...[
                  _RecentAccountsSection(
                    accounts: recentAccounts,
                    onSelect: _fillAccount,
                    onRemove: (username) async {
                      await ref.read(recentAccountsProvider.notifier).remove(username);
                    },
                    onClearAll: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('清空记录'),
                          content: const Text('确定清除本设备所有已记住的账号？'),
                          actions: [
                            TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
                            FilledButton(onPressed: () => ctx.pop(true), child: const Text('确定')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(recentAccountsProvider.notifier).clearAll();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('使用其他账号登录',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ]),
                  const SizedBox(height: 20),
                ],

                // ── Login form ───────────────────────────────────────────────
                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _usernameCtrl.clear(),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _passwordCtrl.clear(),
                        ),
                        IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ],
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Text('记住我',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 14)),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('没有账号？注册'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: Text('忘记密码？',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent accounts section ──────────────────────────────────────────────────

class _RecentAccountsSection extends StatelessWidget {
  final List<RecentAccount> accounts;
  final void Function(RecentAccount) onSelect;
  final void Function(String username) onRemove;
  final VoidCallback onClearAll;

  const _RecentAccountsSection({
    required this.accounts,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('最近登录',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: onClearAll,
              child: Text('清除全部',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...accounts.map((a) => _RecentAccountTile(
              account: a,
              fmt: fmt,
              onSelect: () => onSelect(a),
              onRemove: () => onRemove(a.username),
            )),
      ],
    );
  }
}

class _RecentAccountTile extends StatelessWidget {
  final RecentAccount account;
  final DateFormat fmt;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _RecentAccountTile({
    required this.account,
    required this.fmt,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _roleColor(account.role).withOpacity(0.15),
                child: Text(
                  account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _roleColor(account.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('@${account.username}  ·  ${account.roleLabel}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(account.lastLoginAt),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return Colors.red.shade700;
      case 'supervisor': return Colors.blue.shade700;
      default:           return Colors.green.shade700;
    }
  }
}
