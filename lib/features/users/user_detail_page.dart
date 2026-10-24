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
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';
import '../../ui/modals.dart';
import '../../ui/toast.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

const userTabs = ['profile', 'workspaces', 'classrooms'];

const _outcomes = {
  ModerationAction.suspend: ('Suspend user completed', ToastTone.warning),
  ModerationAction.ban: ('Ban user completed', ToastTone.danger),
  ModerationAction.delete: ('Delete user completed', ToastTone.danger),
  ModerationAction.warn: ('Warning issued', ToastTone.info),
  ModerationAction.reinstate: ('Account reinstated', ToastTone.success),
};

const _cellStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: .28, color: Dak.body);
const _nameStyle = TextStyle(fontSize: 16, letterSpacing: -.2, color: Dak.heading);

const List<Track> _wsCols = [
  (min: 120, fr: 2.6),
  (min: 60, fr: 1.2),
  (min: 60, fr: 1.4),
  (min: 70, fr: 1.5),
  (min: 70, fr: 1.4),
  (min: 60, fr: .9),
];
const List<Track> _crCols = [(min: 120, fr: 2.2), (min: 70, fr: 1.5), (min: 70, fr: 2.6), (min: 90, fr: 1)];

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.id, required this.tab});

  final String id;
  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(query('/admin/users/$id'));
    final json = async.value;
    if (json == null) {
      return PanelPage(children: [StateText(async.hasError ? errorMessage(async.error!) : 'Loading…', error: async.hasError)]);
    }
    final detail = AdminUserDetail.fromJson(json as Map<String, dynamic>);
    final user = detail.user;
    final isAdmin = ref.watch(authProvider)?.isAdmin ?? false;
    final status = accountStatusLabel[user.status] ?? user.status;
    String tabHref(String t) => t == 'profile' ? '/users/${user.id}' : '/users/${user.id}?tab=$t';

    Future<void> act(ModerationAction action) async {
      final reason = await showActionModal(context, action);
      if (reason == null) return;
      final toast = ref.read(toastProvider.notifier);
      try {
        final result = await ref.read(apiProvider).post<dynamic>('/admin/users/$id/${action.name}', {'reason': reason});
        final (title, tone) = _outcomes[action]!;
        toast.show(title, tone: tone);
        if (result is Map && result['deleted'] == true) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) context.go('/users');
          });
        } else {
          invalidateQueries(ref);
        }
      } catch (e) {
        toast.show('Action failed', message: errorMessage(e), tone: ToastTone.danger);
      }
    }

    return PanelPage(
      children: [
        const BackLink(href: '/users'),
        PageHeader(
          title: 'User Details',
          subtitle: '${user.displayId} · ${accountTypeLabel(user.accountType).toLowerCase()}',
          actions: [
            AdmButton(label: 'Warn', onTap: () => act(ModerationAction.warn), border: Adm.blue, color: Adm.blue),
            if (user.status == 'ACTIVE')
              AdmButton(
                label: 'Suspend Account',
                onTap: () => act(ModerationAction.suspend),
                icon: 'icons/user-minus-yellow.svg',
                border: Adm.warning,
                color: Adm.warning,
              )
            else
              AdmButton(label: 'Reinstate', onTap: () => act(ModerationAction.reinstate), border: Adm.success, color: Adm.success),
            AdmButton(
              label: 'Ban User',
              onTap: user.status == 'BANNED' ? null : () => act(ModerationAction.ban),
              icon: 'icons/banned-white.svg',
              fill: Adm.danger,
              fontSize: 14,
              disabledOpacity: .5,
            ),
            if (isAdmin)
              AdmButton(label: 'Delete User', onTap: () => act(ModerationAction.delete), icon: 'icons/delete.svg', fill: Adm.dangerDark),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(src: user.avatarUrl, name: user.name, size: 60),
            const SizedBox(width: 11),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -.2, color: Dak.heading),
                  ),
                  const SizedBox(height: 8),
                  Text(user.email, style: _cellStyle),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(label: status, tone: accountStatusTone(status)),
                      if (user.reports > 0) ...[
                        const SizedBox(width: 12),
                        Text('${user.reports} reports', style: const TextStyle(fontSize: 14, color: Adm.dangerText)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Chips(
          label: 'User sections',
          value: tab,
          items: [
            ChipItem('profile', 'Profile', href: tabHref('profile')),
            ChipItem('workspaces', 'Workspaces', href: tabHref('workspaces')),
            ChipItem('classrooms', 'Classrooms', href: tabHref('classrooms')),
          ],
        ),
        if (tab == 'profile')
          Gap(
            24,
            children: [
              DetailCard(
                title: 'Account Details',
                children: [
                  DetailRow(label: 'Username', value: user.username != null ? '@${user.username}' : '—'),
                  DetailRow(label: 'Phone', value: user.phone ?? '—'),
                  DetailRow(label: 'Country', value: user.country ?? '—'),
                  DetailRow(label: 'City', value: user.city ?? '—'),
                  DetailRow(label: 'Account type', value: accountTypeLabel(user.accountType)),
                  if (user.businessVerification != null)
                    DetailRow(label: 'Business verification', value: titleCase(user.businessVerification!)),
                  DetailRow(label: 'Email verified', value: user.emailVerified ? 'Yes' : 'No'),
                  DetailRow(label: 'Joined', value: formatDate(user.joinedAt)),
                  DetailRow(label: 'Last active', value: timeAgo(user.lastActiveAt)),
                  DetailRow(label: 'Profile visibility', value: titleCase(user.visibility)),
                ],
              ),
              if (detail.history.isNotEmpty)
                DetailCard(
                  title: 'Moderation history',
                  children: [
                    for (final h in detail.history)
                      DetailRow(label: '${titleCase(h.type)} · ${timeAgo(h.createdAt)}', value: '${h.reason} — ${h.actor.name}'),
                  ],
                ),
            ],
          ),
        if (tab == 'workspaces')
          _TableCard(
            title: 'workspaces Details',
            minWidth: 640,
            tracks: _wsCols,
            headers: const [
              ('Workspace', TextAlign.left),
              ('Role', TextAlign.left),
              ('Member', TextAlign.center),
              ('Canvases', TextAlign.center),
              ('Visibility', TextAlign.left),
              ('Updated', TextAlign.right),
            ],
            empty: detail.workspaces.isEmpty ? 'Not a member of any workspace.' : null,
            rowGap: 32,
            rows: [
              for (final w in detail.workspaces)
                [
                  Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _nameStyle),
                  Text(titleCase(w.role), style: _cellStyle),
                  Text(
                    pad2(w.members),
                    textAlign: TextAlign.center,
                    style: _cellStyle.copyWith(color: Dak.heading),
                  ),
                  Text(
                    pad2(w.canvases),
                    textAlign: TextAlign.center,
                    style: _cellStyle.copyWith(color: Dak.heading),
                  ),
                  Text(titleCase(w.visibility), style: _cellStyle),
                  Text(timeAgo(w.updatedAt), textAlign: TextAlign.right, style: _cellStyle),
                ],
            ],
          ),
        if (tab == 'classrooms')
          _TableCard(
            title: 'Classrooms Details',
            minWidth: 560,
            tracks: _crCols,
            headers: const [
              ('Classroom', TextAlign.left),
              ('Role', TextAlign.left),
              ('Progress', TextAlign.left),
              ('Status', TextAlign.center),
            ],
            empty: detail.classrooms.isEmpty ? 'No classrooms.' : null,
            rowGap: 24,
            rows: [
              for (final c in detail.classrooms)
                [
                  Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _nameStyle),
                  Text(titleCase(c.role), style: _cellStyle),
                  Text(c.progress == null ? '—' : '${c.progress}%', style: _cellStyle.copyWith(color: Dak.heading)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: StatusBadge(label: titleCase(c.status), tone: c.status == 'ACTIVE' ? BadgeTone.success : BadgeTone.neutral),
                  ),
                ],
            ],
          ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.title,
    required this.minWidth,
    required this.tracks,
    required this.headers,
    required this.rows,
    required this.rowGap,
    this.empty,
  });

  final String title;
  final double minWidth;
  final List<Track> tracks;
  final List<(String, TextAlign)> headers;
  final List<List<Widget>> rows;
  final double rowGap;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      815,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(context.dvw(16, 2.1, 40), 24, context.dvw(16, 2.1, 40), 40),
        decoration: BoxDecoration(
          color: Dak.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Dak.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.toUpperCase(), style: cardTitleStyle()),
            const SizedBox(height: 32),
            ScrollTable(
              minWidth: minWidth,
              builder: (width) {
                // gap-4 between columns comes out of the width before the tracks share it.
                final widths = trackWidths(width - 16.0 * (tracks.length - 1), tracks);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Dak.muted.withValues(alpha: .5))),
                      ),
                      child: TrackRow(
                        widths: widths,
                        gap: 16,
                        cells: [for (final (h, align) in headers) Text(h, textAlign: align, style: _cellStyle)],
                      ),
                    ),
                    if (empty != null)
                      Padding(
                        padding: EdgeInsets.only(top: rowGap),
                        child: Text(empty!, style: const TextStyle(fontSize: 14, color: Dak.body)),
                      ),
                    for (final cells in rows)
                      Padding(
                        padding: EdgeInsets.only(top: rowGap),
                        child: TrackRow(widths: widths, gap: 16, cells: cells),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
