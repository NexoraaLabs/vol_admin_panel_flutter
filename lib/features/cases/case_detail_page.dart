import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/format.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/modals.dart';
import '../../ui/toast.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

const _outcomes = {
  ModerationAction.dismiss: ('Dismiss case completed', ToastTone.info),
  ModerationAction.warn: ('Issue warning completed', ToastTone.info),
  ModerationAction.suspend: ('Suspend user completed', ToastTone.warning),
  ModerationAction.ban: ('Ban user completed', ToastTone.danger),
};

class CaseDetailPage extends ConsumerWidget {
  const CaseDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(query('/admin/cases/$id'));
    final json = async.value;
    if (json == null) {
      return PanelPage(children: [StateText(async.hasError ? errorMessage(async.error!) : 'Loading…', error: async.hasError)]);
    }
    final detail = AdminCaseDetail.fromJson(json as Map<String, dynamic>);
    final c = detail.info;

    Future<void> run(String kind, {String reason = ''}) async {
      final toast = ref.read(toastProvider.notifier);
      try {
        await ref.read(apiProvider).post<dynamic>('/admin/cases/${c.id}/$kind', {'reason': reason});
        invalidateQueries(ref);
        if (kind == 'review') {
          toast.show('Case marked in review');
        } else if (kind == 'reopen') {
          toast.show('Case reopened');
        } else {
          final (title, tone) = _outcomes[ModerationAction.values.byName(kind)]!;
          toast.show(title, tone: tone);
          if (kind == 'dismiss') {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted) context.go('/cases');
            });
          }
        }
      } catch (e) {
        toast.show('Action failed', message: errorMessage(e), tone: ToastTone.danger);
      }
    }

    Future<void> act(ModerationAction action) async {
      final reason = await showActionModal(context, action);
      if (reason != null) await run(action.name, reason: reason);
    }

    Widget outline(String label, VoidCallback onTap) => AdmButton(label: label, onTap: onTap, border: Dak.body, color: Dak.body);

    return PanelPage(
      children: [
        const BackLink(href: '/cases'),
        PageHeader(
          title: c.title,
          subtitle: c.displayId,
          actions: [
            StatusBadge(
              label: caseStatusLabel[c.status] ?? c.status,
              tone: c.status == 'OPEN' ? BadgeTone.success : (c.status == 'IN_REVIEW' ? BadgeTone.warning : BadgeTone.neutral),
            ),
          ],
        ),
        DetailCard(
          title: 'Case details',
          footer: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('RECOMMENDATION', style: cardTitleStyle(Dak.body)),
              Text(
                (c.recommendation ?? (c.reportCount >= 3 ? 'Suspension recommended' : 'Review and decide')).toUpperCase(),
                style: cardTitleStyle(),
              ),
            ],
          ),
          children: [
            DetailRow(
              label: 'Reported account',
              child: Pressable(
                onTap: () => context.go('/users/${c.reportedUser.id}'),
                child: Hover(
                  builder: (context, hovered) => Text(
                    c.reportedUser.name,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: Dak.cta,
                      decoration: hovered ? TextDecoration.underline : null,
                      decorationColor: Dak.cta,
                    ),
                  ),
                ),
              ),
            ),
            DetailRow(label: 'Violation', value: c.violation),
            DetailRow(label: 'Escalated', value: formatDate(c.escalatedAt)),
            DetailRow(label: 'Reports', value: '${c.reportCount}'),
            if (c.assignee != null) DetailRow(label: 'Assigned to', value: c.assignee!.name),
            if (c.resolvedAt != null) DetailRow(label: 'Closed', value: formatDate(c.resolvedAt)),
          ],
        ),
        DetailCard(
          title: 'evidence',
          children: [for (final item in c.evidence) DetailRow(label: item)],
        ),
        DetailCard(
          title: 'reports',
          children: [
            for (final r in detail.reports)
              DetailRow(
                label: '${r.reason} · ${titleCase(r.targetType)} · ${timeAgo(r.createdAt)}',
                value: '${r.reporter.name}${r.details != null ? ' — “${r.details}”' : ''}',
              ),
          ],
        ),
        if (detail.actions.isNotEmpty)
          DetailCard(
            title: 'actions taken',
            children: [
              for (final a in detail.actions)
                DetailRow(label: '${titleCase(a.type)} · ${timeAgo(a.createdAt)}', value: '${a.reason} — ${a.actor.name}'),
            ],
          ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: c.closed
              ? [outline('Reopen Case', () => run('reopen'))]
              : [
                  if (c.status == 'OPEN') outline('Mark In Review', () => run('review')),
                  outline('Dismiss Case', () => act(ModerationAction.dismiss)),
                  outline('Issue Warning', () => act(ModerationAction.warn)),
                  AdmButton(
                    label: 'Suspend Account',
                    onTap: () => act(ModerationAction.suspend),
                    icon: 'icons/user-minus-yellow.svg',
                    border: Adm.warning,
                    color: Adm.warning,
                  ),
                  AdmButton(
                    label: 'Ban User',
                    onTap: () => act(ModerationAction.ban),
                    icon: 'icons/banned-white.svg',
                    fill: Adm.danger,
                    fontSize: 14,
                  ),
                ],
        ),
      ],
    );
  }
}
