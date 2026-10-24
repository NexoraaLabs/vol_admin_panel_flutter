import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/format.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/tokens.dart';
import '../../ui/layout.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

const _filters = [
  ChipItem('', 'All'),
  ChipItem('OPEN', 'Open'),
  ChipItem('IN_REVIEW', 'In Review'),
  ChipItem('RESOLVED', 'Resolved'),
  ChipItem('DISMISSED', 'Dismissed'),
];

const caseTone = {'OPEN': BadgeTone.success, 'IN_REVIEW': BadgeTone.warning, 'RESOLVED': BadgeTone.info, 'DISMISSED': BadgeTone.neutral};

const _border = {'OPEN': Adm.success, 'IN_REVIEW': Adm.warning, 'RESOLVED': Adm.blue, 'DISMISSED': Dak.muted};

class CasesPage extends ConsumerStatefulWidget {
  const CasesPage({super.key});

  @override
  ConsumerState<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends ConsumerState<CasesPage> {
  var _filter = '';
  var _page = 1;
  var _q = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(query(withQuery('/admin/cases', {'status': _filter, 'q': _q.trim(), 'page': _page, 'limit': 10})));
    final json = async.value;
    final data = json == null ? null : AdminCaseList.fromJson(json as Map<String, dynamic>);
    final stats = data == null
        ? <(String, int)>[]
        : [
            ('Open escalations', data.stats.open),
            ('In review', data.stats.inReview),
            ('Reopened this month', data.stats.reopenedThisMonth),
          ];

    return PanelPage(
      children: [
        const PageHeader(
          title: 'Cases',
          subtitle: 'Reports from members are grouped into one case per account. Decisions here are final and audit-logged.',
        ),
        if (stats.isNotEmpty)
          Wrap(
            spacing: 19,
            runSpacing: 19,
            children: [
              for (final (label, value) in stats)
                Container(
                  height: 120,
                  constraints: const BoxConstraints(minWidth: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    color: Dak.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Dak.cta),
                    boxShadow: const [BoxShadow(color: Color(0x409436FB), offset: Offset(0, 4), blurRadius: 4)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 16 / 14,
                          letterSpacing: .28,
                          color: Dak.body,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pad2(value),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          height: 24 / 28,
                          letterSpacing: .28,
                          color: Dak.heading,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chips(
              label: 'Filter cases',
              items: _filters,
              value: _filter,
              onChanged: (v) => setState(() {
                _filter = v;
                _page = 1;
              }),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AdmField(
                hint: 'Search by title, violation or ESC id',
                fill: Adm.searchFill,
                semanticLabel: 'Search cases',
                onChanged: (v) => setState(() {
                  _q = v;
                  _page = 1;
                }),
              ),
            ),
          ],
        ),
        if (data == null && async.hasError) StateText(errorMessage(async.error!), error: true),
        if (data != null && data.page.items.isEmpty) const StateText('No cases here. 🎉'),
        if (data != null && data.page.items.isNotEmpty)
          MaxWidth(
            750,
            child: Gap(16, children: [for (final c in data.page.items) _CaseRow(item: c)]),
          ),
        if (data != null && data.page.pages > 1)
          MaxWidth(
            750,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AdmButton(
                  label: 'Previous',
                  onTap: _page > 1 ? () => setState(() => _page--) : null,
                  border: Dak.muted,
                  color: Dak.muted,
                  radius: 30,
                  padX: 24,
                  weight: FontWeight.w600,
                  disabledOpacity: .4,
                ),
                Text('Page $_page of ${data.page.pages}', style: const TextStyle(fontSize: 14, color: Dak.body)),
                AdmButton(
                  label: 'Next',
                  onTap: _page < data.page.pages ? () => setState(() => _page++) : null,
                  fill: Dak.cta,
                  radius: 30,
                  padX: 24,
                  weight: FontWeight.w600,
                  disabledOpacity: .4,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({required this.item});

  final AdminCase item;

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: .28, color: Dak.body);
    final c = item;
    return Hover(
      builder: (context, hovered) => Pressable(
        onTap: () => context.go('/cases/${c.displayId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: hovered ? Adm.rowHover : Dak.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (_border[c.status] ?? Dak.muted).withValues(alpha: .6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Figma writes the id as "Esc-0001" in the list and "ESC-0001" on the detail page.
                    Text(c.displayId.replaceFirst('ESC', 'Esc'), style: small),
                    const SizedBox(height: 16),
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 24 / 18,
                        letterSpacing: .28,
                        color: Dak.heading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${c.reporter?.name ?? 'Member report'} · opened ${formatDate(c.createdAt)} · '
                      '${c.reportCount} report${c.reportCount == 1 ? '' : 's'}',
                      style: small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              StatusBadge(label: caseStatusLabel[c.status] ?? c.status, tone: caseTone[c.status] ?? BadgeTone.neutral),
            ],
          ),
        ),
      ),
    );
  }
}
