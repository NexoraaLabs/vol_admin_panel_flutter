import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/browser/browser.dart';
import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/widgets.dart';
import 'auth_shell.dart';

/// sessionStorage key carrying `{ email, code }` from the login screen to the verify screen, which
/// shows the code. Temporary: only set while the API sends codes back (SHOW_SIGNUP_CODE), until
/// emails are delivered.
const devOtpKey = 'vol-admin-dev-otp';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.next});

  final String? next;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  var _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final address = _email.text.trim();
    if (address.isEmpty || !address.contains('@') || _password.text.isEmpty || _sending) {
      setState(() => _error = address.isEmpty || !address.contains('@') ? 'Enter your email address.' : 'Enter your password.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      // The API answers the same way for every address, so it can't be used to find admin emails.
      // Temporary: the password lets the API show the code on screen until emails are delivered.
      final res = await ref.read(apiProvider).post<dynamic>('/auth/admin/login', {'email': address, 'password': _password.text});
      final devCode = res is Map ? res['devCode'] as String? : null;
      if (devCode != null) sessionSet(devOtpKey, jsonEncode({'email': address, 'code': devCode}));
      if (!mounted) return;
      context.go(Uri(path: '/verify', queryParameters: {'email': address, 'next': ?widget.next}).toString());
    } catch (e) {
      setState(() {
        _error = errorMessage(e);
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Dak.heading);
    return AuthShell(
      children: [
        const AuthHeading(
          title: 'Admin sign in',
          body: [TextSpan(text: 'Restricted access. Unauthorized attempts are recorded.')],
        ),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Email', style: label),
              const SizedBox(height: 16),
              AdmField(
                controller: _email,
                hint: 'User@domain.com',
                height: 56,
                borderColor: Dak.heading,
                borderWidth: 1,
                hintColor: Dak.body,
                padRight: 26,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 24, right: 12),
                  child: AssetIcon('icons/gmail.svg', width: 24, height: 24),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 40),
              const Text('Password', style: label),
              const SizedBox(height: 16),
              AdmField(
                controller: _password,
                hint: 'Password',
                height: 56,
                borderColor: Dak.heading,
                borderWidth: 1,
                hintColor: Dak.body,
                padLeft: 34,
                padRight: 26,
                obscure: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Adm.danger),
                ),
              ],
              const SizedBox(height: 40),
              AuthButton(label: _sending ? 'Sending code…' : 'Login', onTap: _sending ? null : _submit),
            ],
          ),
        ),
      ],
    );
  }
}
