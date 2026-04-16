import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

// ── Design tokens (shared with login) ────────────────────────────────────────
const _bgColor     = Color(0xFFF5F3F0);
const _primary     = Color(0xFF4A6CF7);
const _titleColor  = Color(0xFF1A1A2E);
const _hintColor   = Color(0xFFC5C5CE);
const _mutedColor  = Color(0xFFB5B5C0);
const _inputBg     = Colors.white;
const _checkBg     = Color(0xFFF7F6F4);
const _checkBorder = Color(0xFFD4D2CE);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameCtrl        = TextEditingController();
  final _nameCtrl            = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading              = false;
  bool _obscurePassword      = true;
  bool _obscureConfirm       = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _nameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 6) {
      setState(() => _error = AppLocalizations.of(context)!.registerValidation);
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _error = AppLocalizations.of(context)!.registerPasswordMismatch);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(currentUserProvider.notifier).register(
        username: _usernameCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() {
        _error = msg is List ? msg.join(', ') : (msg ?? AppLocalizations.of(context)!.registerFailed);
      });
    } catch (e) {
      setState(() => _error = '注册失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Password rule checks
  bool get _ruleLength     => _passwordCtrl.text.length >= 6 && _passwordCtrl.text.length <= 20;
  bool get _ruleLowercase  => _passwordCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _ruleDigit      => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _ruleOnlyAlnum  => _passwordCtrl.text.isEmpty ||
      RegExp(r'^[a-z0-9]+$').hasMatch(_passwordCtrl.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: _titleColor,
                    ),
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Header ────────────────────────────────────────────
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.warehouse_rounded,
                        size: 22,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context)!.registerTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: _titleColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)!.registerSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _mutedColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Input fields ──────────────────────────────────────
                    _InputCard(
                      child: _InputRow(
                        controller: _usernameCtrl,
                        hint: AppLocalizations.of(context)!.loginUsername,
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        suffix: _usernameCtrl.text.isNotEmpty
                            ? _ClearButton(onTap: () => setState(() => _usernameCtrl.clear()))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InputCard(
                      child: _InputRow(
                        controller: _nameCtrl,
                        hint: AppLocalizations.of(context)!.registerName,
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        suffix: _nameCtrl.text.isNotEmpty
                            ? _ClearButton(onTap: () => setState(() => _nameCtrl.clear()))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InputCard(
                      child: _InputRow(
                        controller: _passwordCtrl,
                        hint: AppLocalizations.of(context)!.loginPassword,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_passwordCtrl.text.isNotEmpty)
                              _ClearButton(onTap: () => setState(() => _passwordCtrl.clear())),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
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
                    const SizedBox(height: 10),
                    _InputCard(
                      child: _InputRow(
                        controller: _confirmPasswordCtrl,
                        hint: AppLocalizations.of(context)!.registerConfirmPassword,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _register(),
                        onChanged: (_) => setState(() {}),
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_confirmPasswordCtrl.text.isNotEmpty)
                              _ClearButton(
                                  onTap: () =>
                                      setState(() => _confirmPasswordCtrl.clear())),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                              child: Icon(
                                _obscureConfirm
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
                    const SizedBox(height: 14),

                    // ── Password rules ────────────────────────────────────
                    _PasswordRules(
                      rules: [
                        _PasswordRule(AppLocalizations.of(context)!.passwordRuleLength,   _ruleLength),
                        _PasswordRule(AppLocalizations.of(context)!.passwordRuleLowercase, _ruleLowercase),
                        _PasswordRule(AppLocalizations.of(context)!.passwordRuleDigit,     _ruleDigit),
                        _PasswordRule(AppLocalizations.of(context)!.passwordRuleAlnum,     _ruleOnlyAlnum),
                      ],
                      show: _passwordCtrl.text.isNotEmpty,
                    ),

                    // ── Error message ─────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                            color: Color(0xFFE53935), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Register button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _loading
                              ? _primary.withValues(alpha: 0.5)
                              : _primary.withValues(alpha: 0.9),
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
                            onTap: _loading ? null : _register,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.registerButton,
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

                    // ── Login link ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.registerHaveAccount,
                          style: const TextStyle(fontSize: 13, color: _mutedColor),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            AppLocalizations.of(context)!.loginButton,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Password rules section ────────────────────────────────────────────────────

class _PasswordRule {
  final String label;
  final bool passed;
  const _PasswordRule(this.label, this.passed);
}

class _PasswordRules extends StatelessWidget {
  final List<_PasswordRule> rules;
  final bool show;
  const _PasswordRules({required this.rules, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: rules.map((r) => _RuleItem(rule: r)).toList(),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final _PasswordRule rule;
  const _RuleItem({required this.rule});

  @override
  Widget build(BuildContext context) {
    final color = rule.passed ? const Color(0xFF43A047) : _mutedColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: rule.passed
                  ? const Color(0xFF43A047).withValues(alpha: 0.12)
                  : _checkBg,
              border: Border.all(
                color: rule.passed
                    ? const Color(0xFF43A047).withValues(alpha: 0.5)
                    : _checkBorder,
                width: 1,
              ),
              shape: BoxShape.circle,
            ),
            child: rule.passed
                ? const Icon(Icons.check, size: 9, color: Color(0xFF43A047))
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            rule.label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

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

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const _InputRow({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Icon(icon, size: 17, color: _hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _titleColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: _hintColor),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: suffix,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
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
