import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'asset_icon.dart';
import 'layout.dart';
import 'widgets.dart';

/// Copy and confirm-button colour for one moderation action (components/modals/moderation.ts).
class ActionCopy {
  const ActionCopy({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.confirmColor,
    this.confirmWord,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final Color confirmColor;

  /// When set, the admin must type this word before confirming (Figma's ban/delete modals).
  final String? confirmWord;
}

enum ModerationAction { suspend, ban, delete, warn, dismiss, reinstate }

// Per Figma's Composer Modal frames (789:4313, 789:4603, 789:4637, 801:9574, 801:9548).
const moderationCopy = {
  ModerationAction.suspend: ActionCopy(
    title: 'Suspend this account?',
    description: 'The user loses access to workspaces, classrooms and community until restored.',
    confirmLabel: 'Suspend User',
    confirmColor: Adm.warning,
  ),
  ModerationAction.ban: ActionCopy(
    title: 'Permanently ban this account?',
    description: 'The account is permanently closed. Content is hidden and re-registration is blocked.',
    confirmLabel: 'Ban user',
    confirmColor: Adm.danger,
    confirmWord: 'BAN',
  ),
  ModerationAction.delete: ActionCopy(
    title: 'Delete this account and all data?',
    description: 'Irreversible. Personal data is erased under the platform retention policy',
    confirmLabel: 'Delete user',
    confirmColor: Adm.dangerDark,
    confirmWord: 'DELETE',
  ),
  ModerationAction.warn: ActionCopy(
    title: 'Issue formal warning',
    description: 'The account holder receives a warning email and an in-app notice.',
    confirmLabel: 'Issue Warning',
    confirmColor: Adm.blue,
  ),
  ModerationAction.dismiss: ActionCopy(
    title: 'Dismiss escalation',
    description: 'The report is closed with no action against the account.',
    confirmLabel: 'Dismiss Case',
    confirmColor: Adm.blue,
  ),
  ModerationAction.reinstate: ActionCopy(
    title: 'Reinstate this account?',
    description: 'The user regains access to workspaces, classrooms and community immediately.',
    confirmLabel: 'Reinstate',
    confirmColor: Adm.success,
  ),
};

/// Asks for the audit-log reason behind a moderation action. Resolves to the reason, or null when
/// the admin backs out.
Future<String?> showActionModal(BuildContext context, ModerationAction action) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (_) => _ActionModal(copy: moderationCopy[action]!),
  );
}

class _ActionModal extends StatefulWidget {
  const _ActionModal({required this.copy});

  final ActionCopy copy;

  @override
  State<_ActionModal> createState() => _ActionModalState();
}

class _ActionModalState extends State<_ActionModal> {
  final _reason = TextEditingController();
  final _typed = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _typed.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _reason.text.trim().isNotEmpty && (widget.copy.confirmWord == null || _typed.text.trim() == widget.copy.confirmWord);

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: .28, color: Dak.body);
    final buttonText = heading(const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: .28, color: Dak.heading));

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 768, maxHeight: context.screenHeight * .9),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC6C6CD)),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3),
              BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Dak.border,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.title,
                            style: TextStyle(
                              fontSize: context.isSm ? 24 : 20,
                              fontWeight: FontWeight.w600,
                              height: 32 / 24,
                              color: Dak.heading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            copy.description,
                            style: const TextStyle(fontSize: 14, height: 20 / 14, color: Dak.body),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Pressable(
                      onTap: () => Navigator.pop(context),
                      label: 'Close',
                      child: const Padding(padding: EdgeInsets.all(8), child: AssetIcon('icons/close-x.svg', width: 14, height: 14)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Dak.surface,
                    border: Border.all(color: Dak.border.withValues(alpha: .4)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(25, 41, 25, 25),
                    child: Gap(
                      16,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Gap(
                            8,
                            children: [
                              const Text('Reason (recorded in audit log)', style: label),
                              AdmField(
                                controller: _reason,
                                hint: 'Type here...',
                                autofocus: true,
                                lines: 4,
                                height: 121,
                                borderColor: Dak.body,
                                borderWidth: 1,
                                padLeft: 17,
                                padRight: 17,
                                hintColor: Dak.muted,
                                lineHeight: 1.5,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        if (copy.confirmWord != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Gap(
                              8,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    style: label,
                                    children: [
                                      const TextSpan(text: 'Type '),
                                      TextSpan(
                                        text: copy.confirmWord,
                                        style: const TextStyle(color: Adm.danger),
                                      ),
                                      const TextSpan(text: ' to continue'),
                                    ],
                                  ),
                                ),
                                AdmField(
                                  controller: _typed,
                                  hint: 'Type here...',
                                  height: 56,
                                  borderColor: Dak.body,
                                  borderWidth: 1,
                                  padLeft: 17,
                                  padRight: 17,
                                  hintColor: Dak.muted,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _confirm(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                color: Dak.border,
                constraints: const BoxConstraints(minHeight: 121),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: AdmButton(
                          label: 'Cancel',
                          onTap: () => Navigator.pop(context),
                          width: double.infinity,
                          radius: 16,
                          border: Dak.heading,
                          textStyle: buttonText.copyWith(color: Colors.white),
                          shadow: const [BoxShadow(color: Color(0x669436FB), offset: Offset(0, 8), blurRadius: 12)],
                        ),
                      ),
                    ),
                    SizedBox(width: context.isSm ? 24 : 16),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 166),
                        child: AdmButton(
                          label: copy.confirmLabel,
                          onTap: _canConfirm ? _confirm : null,
                          width: double.infinity,
                          radius: 16,
                          fill: copy.confirmColor,
                          textStyle: buttonText,
                          disabledOpacity: .5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    if (_canConfirm) Navigator.pop(context, _reason.text.trim());
  }
}

/// The "Sign Out" confirmation. Resolves to true when the admin confirms.
Future<bool> showSignOutModal(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (_) => const _SignOutModal(),
  );
  return yes ?? false;
}

class _SignOutModal extends StatelessWidget {
  const _SignOutModal();

  @override
  Widget build(BuildContext context) {
    final buttonStyle = GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w500);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 325),
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: const Color(0xFF4D4955), borderRadius: BorderRadius.circular(30)),
                child: Stack(
                  children: [
                    // signout-glow.svg is a blurred circle, which flutter_svg can't render; a radial
                    // gradient draws the same glow.
                    Positioned(
                      left: 70.5 - 185,
                      bottom: 256 - 193.5 - 185,
                      width: 370,
                      height: 370,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0x66C793FF), Color(0x00C793FF)])),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 70, 30, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sign Out',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Dak.heading),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(
                            width: 245,
                            child: Text(
                              'Are you sure you want to logout of your account?',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Dak.body),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 261),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _RoundButton(
                                    onTap: () => Navigator.pop(context, false),
                                    color: Colors.white.withValues(alpha: .7),
                                    child: Text('Cancel', style: buttonStyle.copyWith(color: Dak.surface)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _RoundButton(
                                    onTap: () => Navigator.pop(context, true),
                                    color: Dak.surface,
                                    child: ShaderMask(
                                      shaderCallback: (r) => const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.white, Color(0xFF999999)],
                                      ).createShader(r),
                                      child: Text('Yes', style: buttonStyle.copyWith(color: Colors.white)),
                                    ),
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
              ),
              Positioned(
                top: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.only(left: 10, right: 15),
                  decoration: const BoxDecoration(color: Dak.surface, shape: BoxShape.circle),
                  child: const Center(child: AssetIcon('icons/logout-lg.svg', width: 46, height: 46)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, required this.color, required this.child});

  final VoidCallback onTap;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: child,
      ),
    );
  }
}
