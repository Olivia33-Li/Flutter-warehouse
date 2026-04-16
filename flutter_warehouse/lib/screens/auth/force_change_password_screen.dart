import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Shown when user.mustChangePassword == true after login.
/// User cannot dismiss this — they must change their password first.
class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  ConsumerState<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState
    extends ConsumerState<ForceChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPwd = _oldCtrl.text;
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    final l10n = AppLocalizations.of(context)!;
    if (oldPwd.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _error = l10n.forceChangeEmptyError);
      return;
    }
    if (newPwd.length < 6) {
      setState(() => _error = l10n.forceChangeShortError);
      return;
    }
    if (newPwd != confirm) {
      setState(() => _error = l10n.forceChangeMismatchError);
      return;
    }
    if (newPwd == oldPwd) {
      setState(() => _error = l10n.forceChangeSameError);
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().changePassword(
        oldPassword: oldPwd,
        newPassword: newPwd,
      );
      // Update local user state — clear mustChangePassword flag
      ref.read(currentUserProvider.notifier).clearMustChangePassword();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? AppLocalizations.of(context)!.forceChangeFailed));
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.forceChangeFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_reset, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(l10n.forceChangeTitle,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.forceChangeNotice,
                            style: TextStyle(
                                color: Colors.orange.shade800, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PasswordField(
                    controller: _oldCtrl,
                    label: l10n.forceChangeOldPassword,
                    obscure: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _newCtrl,
                    label: l10n.forceChangeNewPassword,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmCtrl,
                    label: l10n.forceChangeConfirmPassword,
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    action: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l10n.forceChangeButton),
                    ),
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
