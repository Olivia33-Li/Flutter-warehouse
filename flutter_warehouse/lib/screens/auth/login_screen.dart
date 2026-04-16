import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';

// ── Figma design tokens ───────────────────────────────────────────────────────
const _bgColor       = Color(0xFFF5F3F0);
const _primary       = Color(0xFF4A6CF7);
const _titleColor    = Color(0xFF1A1A2E);
const _hintColor     = Color(0xFFC5C5CE);
const _mutedColor    = Color(0xFFB5B5C0);
const _inputBg       = Colors.white;
const _checkBg       = Color(0xFFF7F6F4);
const _checkBorder   = Color(0xFFD4D2CE);

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
      setState(() => _error = AppLocalizations.of(context)!.loginEmptyError);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(currentUserProvider.notifier).login(
        username: username,
        password: password,
        rememberMe: _rememberMe,
      );
      await ref.read(recentAccountsProvider.notifier).refresh();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? AppLocalizations.of(context)!.loginFailedNetwork));
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.loginFailedNetwork);
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
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    final recentAccounts = ref.watch(recentAccountsProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ─────────────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.warehouse_rounded, size: 26, color: _primary),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _titleColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Recent accounts ───────────────────────────────────────
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
                          title: Text(AppLocalizations.of(ctx)!.loginClearAllTitle),
                          content: Text(AppLocalizations.of(ctx)!.loginClearAllContent),
                          actions: [
                            TextButton(onPressed: () => ctx.pop(false), child: Text(AppLocalizations.of(ctx)!.cancel)),
                            FilledButton(onPressed: () => ctx.pop(true), child: Text(AppLocalizations.of(ctx)!.confirm)),
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
                    Expanded(child: Divider(color: _checkBorder.withValues(alpha: 0.8))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(AppLocalizations.of(context)!.loginUseOtherAccount,
                          style: const TextStyle(color: _mutedColor, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: _checkBorder.withValues(alpha: 0.8))),
                  ]),
                  const SizedBox(height: 20),
                ],

                // ── Username input ────────────────────────────────────────
                _InputCard(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.person_outline_rounded, size: 17, color: _hintColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14, color: _titleColor),
                          decoration: _inputDeco(AppLocalizations.of(context)!.loginUsername,
                            suffix: _usernameCtrl.text.isNotEmpty
                                ? _ClearButton(onTap: () => setState(() => _usernameCtrl.clear()))
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Password input ────────────────────────────────────────
                _InputCard(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.lock_outline_rounded, size: 17, color: _hintColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14, color: _titleColor),
                          decoration: _inputDeco(AppLocalizations.of(context)!.loginPassword,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_passwordCtrl.text.isNotEmpty)
                                  _ClearButton(onTap: () => setState(() => _passwordCtrl.clear())),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 16,
                                    color: _hintColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Remember me + Forgot password ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          _Checkbox(checked: _rememberMe),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.loginRememberMe,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/forgot-password'),
                      child: Text(
                        AppLocalizations.of(context)!.loginForgotPassword,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Error message ─────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // ── Login button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _loading ? _primary.withValues(alpha: 0.5) : _primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _loading
                          ? []
                          : [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : _login,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.loginButton,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Register link ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.loginNoAccount,
                      style: const TextStyle(fontSize: 13, color: _mutedColor),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        AppLocalizations.of(context)!.loginRegister,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _primary.withValues(alpha: 0.7),
                        ),
                      ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

InputDecoration _inputDeco(String hint, {Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _hintColor),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(Icons.close, size: 15, color: _hintColor),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: checked ? _primary : _checkBg,
        border: Border.all(
          color: checked ? _primary : _checkBorder,
          width: 1.25,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: checked
          ? const Icon(Icons.check, size: 11, color: Colors.white)
          : null,
    );
  }
}

// ── Recent accounts section ───────────────────────────────────────────────────

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
            Text(
              AppLocalizations.of(context)!.loginRecentTitle,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onClearAll,
              child: Text(
                AppLocalizations.of(context)!.loginClearAll,
                style: const TextStyle(color: _mutedColor, fontSize: 12),
              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _roleColor(account.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _roleColor(account.role),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${account.username}  ·  ${account.roleLabel}',
                        style: const TextStyle(color: _mutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(account.lastLoginAt),
                      style: const TextStyle(color: _hintColor, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.close, size: 15, color: _hintColor),
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

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFFE53935);
      case 'supervisor': return _primary;
      default:           return const Color(0xFF43A047);
    }
  }
}
