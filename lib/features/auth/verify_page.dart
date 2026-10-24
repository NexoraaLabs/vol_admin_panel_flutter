import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/browser/browser.dart';
import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';
import '../../ui/widgets.dart';
import 'auth_shell.dart';
import 'code_input.dart';
import 'login_page.dart';

class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key, required this.email, required this.next});

  final String email;
  final String next;

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  var _code = '';
  var _resent = false;
  var _verifying = false;
  String? _error;

  /// Temporary, until emails are delivered: the code the API sent back after the password check.
  late final String? _devCode = _savedCode();

  String? _savedCode() {
    try {
      final saved = jsonDecode(sessionGet(devOtpKey) ?? 'null');
      return saved is Map && saved['email'] == widget.email ? saved['code'] as String? : null;
    } catch (_) {
      // Nothing saved, or storage unavailable: the admin waits for the email as usual.
      return null;
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6 || _verifying) return;
    setState(() {
      _error = null;
      _verifying = true;
    });
    try {
      final api = ref.read(apiProvider);
      api.setSession(await api.post<Map<String, dynamic>>('/auth/admin/verify', {'email': widget.email, 'code': _code}));
      sessionRemove(devOtpKey);
      if (mounted) context.go(widget.next);
    } catch (e) {
      setState(() {
        _error = errorMessage(e);
        _verifying = false;
      });
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    // A code shown on screen needs the password again, so it can only be re-sent from the login page.
    if (_devCode != null) return context.go('/login');
    try {
      await ref.read(apiProvider).post<dynamic>('/auth/admin/login', {'email': widget.email});
      setState(() => _resent = true);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      children: [
        AuthHeading(
          title: 'Verify your identity',
          body: [
            const TextSpan(text: 'Enter the 6-digit code we emailed to '),
            TextSpan(
              text: widget.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Dak.heading),
            ),
          ],
        ),
        LayoutBuilder(builder: (context, box) => _card(context, (box.maxWidth * .037).clamp(12, 21))),
      ],
    );
  }

  Widget _card(BuildContext context, double padX) {
    return Container(
      constraints: const BoxConstraints(minHeight: 571),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Dak.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Dak.cta),
        boxShadow: const [BoxShadow(color: Color(0x809436FB), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: 4, child: Container(color: Dak.cta)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padX, vertical: 41),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Dak.cta,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33C6C6CD)),
                        boxShadow: const [BoxShadow(color: Color(0x809436FB), offset: Offset(0, 4), blurRadius: 8)],
                      ),
                      child: const AssetIcon('icons/mail-badge.png', width: 40, height: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.dvw(26, 2.4, 32),
                        fontWeight: FontWeight.w600,
                        height: 40 / 32,
                        letterSpacing: -.32,
                        color: Dak.heading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 428),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'If '),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const TextSpan(text: " belongs to an admin account, we've sent it a 6-digit verification code."),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Dak.body),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_devCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Dak.cta),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: "Email delivery isn't set up yet. Your code is "),
                          TextSpan(
                            text: _devCode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.2,
                              color: Dak.heading,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Dak.body),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                CodeInput(onChanged: (v) => setState(() => _code = v), onComplete: _verify),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Adm.danger),
                  ),
                ],
                const SizedBox(height: 40),
                AuthButton(label: _verifying ? 'Verifying…' : 'Verify Email', onTap: _code.length != 6 || _verifying ? null : _verify),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.only(top: 25),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Dak.border.withValues(alpha: .4))),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _resent ? 'A new code is on its way.' : "Didn't receive the email?",
                        style: const TextStyle(fontSize: 14, height: 20 / 14, color: Dak.body),
                      ),
                      const SizedBox(height: 8),
                      Pressable(
                        onTap: _resend,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AssetIcon('icons/refresh.svg', width: 9, height: 9),
                            SizedBox(width: 4),
                            Text(
                              'Resend Email',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: .28, color: Dak.heading),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
