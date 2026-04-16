import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/password_reset_service.dart';
import '../../l10n/app_localizations.dart';

// ── Design tokens (shared with login / register) ──────────────────────────────
const _bgColor    = Color(0xFFF5F3F0);
const _primary    = Color(0xFF4A6CF7);
const _titleColor = Color(0xFF1A1A2E);
const _descColor  = Color(0xFF8E8E9A);
const _mutedColor = Color(0xFFB5B5C0);
const _hintColor  = Color(0xFFC5C5CE);
const _inputBg    = Colors.white;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameCtrl = TextEditingController();
  final _noteCtrl     = TextEditingController();
  bool _loading   = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.forgotEmptyError);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await PasswordResetService().submitRequest(
        username: username,
        userNote: _noteCtrl.text.trim(),
      );
      if (mounted) setState(() => _submitted = true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? AppLocalizations.of(context)!.forgotSubmitFailed));
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.forgotSubmitFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: GestureDetector(
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/login'),
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

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 24),
                  child: _submitted ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF43A047).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 30,
            color: Color(0xFF43A047),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.forgotSuccessTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _titleColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.forgotSuccessDesc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _descColor, height: 1.7),
        ),
        const SizedBox(height: 36),
        _PrimaryButton(
          label: l10n.forgotBackToLogin,
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }

  // ── Form state ────────────────────────────────────────────────────────────

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon + title + description ──────────────────────────────────
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.shield_outlined, size: 30, color: _primary),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.forgotTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _titleColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.forgotSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _descColor, height: 1.7),
        ),
        const SizedBox(height: 28),

        // ── Info card ───────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 17,
                  color: _descColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forgotAdminContact,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _titleColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.forgotAdminDesc,
                      style: const TextStyle(
                          fontSize: 11, color: _mutedColor, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Username input ──────────────────────────────────────────────
        _InputCard(
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.person_outline_rounded,
                  size: 17, color: _hintColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: _titleColor),
                  decoration: InputDecoration(
                    hintText: l10n.loginUsername,
                    hintStyle:
                        const TextStyle(fontSize: 14, color: _hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _usernameCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _usernameCtrl.clear()),
                            child: const Icon(Icons.close,
                                size: 15, color: _hintColor),
                          )
                        : null,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Note input (optional) ───────────────────────────────────────
        Container(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Icon(Icons.notes_outlined,
                    size: 17, color: _hintColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 14, color: _titleColor),
                  decoration: InputDecoration(
                    hintText: l10n.forgotNote,
                    hintStyle:
                        const TextStyle(fontSize: 13, color: _hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // ── Error message ───────────────────────────────────────────────
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),

        // ── Submit button ───────────────────────────────────────────────
        _PrimaryButton(
          label: l10n.forgotSubmit,
          loading: _loading,
          onTap: _loading ? null : _submit,
        ),
        const SizedBox(height: 16),

        // ── Dismiss ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: () =>
              context.canPop() ? context.pop() : context.go('/login'),
          child: Text(
            l10n.forgotDismiss,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _mutedColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: loading
              ? _primary.withValues(alpha: 0.5)
              : _primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      label,
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
    );
  }
}

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
