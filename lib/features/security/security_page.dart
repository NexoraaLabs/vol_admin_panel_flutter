import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/tokens.dart';
import '../../ui/toast.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(authProvider)?.isAdmin ?? false)) {
      return const PanelPage(
        children: [PageHeader(title: 'Security Center', subtitle: 'Only administrators can change access policy.')],
      );
    }
    final async = ref.watch(polledQuery('/admin/security'));
    final json = async.value;
    final data = json == null ? null : SecurityOverview.fromJson(json as Map<String, dynamic>);

    Future<void> toggle(SecurityPolicy p, bool value) async {
      final toast = ref.read(toastProvider.notifier);
      try {
        await ref.read(apiProvider).put<dynamic>('/admin/security', {
          'changes': {p.key: value},
        });
        ref.invalidate(polledQuery('/admin/security'));
        toast.show(
          '${p.label} ${value ? 'enabled' : 'disabled'}',
          message: 'Applies to every account immediately.',
          tone: ToastTone.success,
        );
      } catch (e) {
        toast.show("Couldn't update policy", message: errorMessage(e), tone: ToastTone.danger);
      }
    }

    return PanelPage(
      children: [
        const PageHeader(title: 'Security Center', subtitle: 'Session control, sign-in anomalies and access policy for the admin portal.'),
        if (data != null)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (label, value) in [
                ('Failed sign-ins (24 h)', data.health.securityAlerts24h),
                ('Failed admin logins (24 h)', data.health.failedAdminLogins24h),
                ('Open critical cases', data.health.openCriticalCases),
              ])
                Container(
                  constraints: const BoxConstraints(minWidth: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Dak.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Dak.cta),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 14, color: Dak.body)),
                      const SizedBox(height: 8),
                      Text(
                        '$value',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Dak.heading),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Panel(
          title: 'Access policy',
          subtitle: 'Applies to every account',
          maxWidth: 786,
          child: Gap(
            24,
            children: [
              if (data == null && async.hasError) StateText(errorMessage(async.error!), error: true),
              for (final p in data?.policies ?? const <SecurityPolicy>[])
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: Adm.policyRow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Adm.slate),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.label, style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          AdmToggle(label: p.label, value: p.value, onChanged: (v) => toggle(p, v)),
                        ],
                      ),
                      if (p.hint != null) ...[
                        const SizedBox(height: 10),
                        Text(p.hint!, style: const TextStyle(fontSize: 16, color: Dak.muted)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
