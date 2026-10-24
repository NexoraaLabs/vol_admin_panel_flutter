import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/browser/browser.dart';
import '../../core/format.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../models/paged.dart';
import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

const _pageSize = 10;

// Each chip maps to the API's status/type filters.
const _filters = [
  (value: 'all', label: 'All', params: <String, String>{}),
  (value: 'individual', label: 'Individual', params: {'type': 'INDIVIDUAL'}),
  (value: 'business', label: 'Business', params: {'type': 'BUSINESS'}),
  (value: 'active', label: 'Active', params: {'status': 'ACTIVE'}),
  (value: 'suspended', label: 'Suspended', params: {'status': 'SUSPENDED'}),
  (value: 'banned', label: 'Banned', params: {'status': 'BANNED'}),
];

// Column widths measured from Figma 743:251 (341/186/176/191/142/192px of the 1338px row, plus the
// 110px action button), kept proportional so the table fits laptop widths without scrolling.
const List<Track> _columns = [
  (min: 264, fr: 341),
  (min: 84, fr: 186),
  (min: 76, fr: 176),
  (min: 116, fr: 191),
  (min: 56, fr: 142),
  (min: 76, fr: 192),
  (min: 110, fr: 0),
];

const _cellStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: .28, color: Dak.body);

/// User Management. [initialQuery] comes from the top bar's search (?q=); the router keys this
/// page on it so a new search resets the local state.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  late final _search = TextEditingController(text: widget.initialQuery);
  late var _debounced = widget.initialQuery.trim();
  Timer? _debounce;
  var _filter = 'all';
  var _page = 1;
  var _exporting = false;
  String? _exportError;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Map<String, Object?> get _params => {..._filters.firstWhere((f) => f.value == _filter).params, 'q': _debounced};

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _exportError = null;
    });
    try {
      final csv = await ref.read(apiProvider).text(withQuery('/admin/users/export', _params));
      downloadText('vol-users.csv', csv, 'text/csv');
    } catch (e) {
      _exportError = errorMessage(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(query(withQuery('/admin/users', {..._params, 'page': _page, 'limit': _pageSize})));
    final json = async.value;
    final data = json == null ? null : Paged.fromJson(json as Map<String, dynamic>, AdminUserRow.fromJson);
    final error = data == null ? async.error : null;

    return PanelPage(
      children: [
        PageHeader(
          title: 'User Management',
          subtitle: 'Every individual and business account.',
          actions: [
            AdmButton(
              label: _exporting ? '…' : 'Export',
              onTap: _exporting ? null : _export,
              icon: 'icons/export.svg',
              iconSize: 24,
              fill: Dak.cta,
              width: 123,
              weight: FontWeight.w700,
            ),
          ],
        ),
        if (_exportError != null) Text(_exportError!, style: const TextStyle(fontSize: 14, color: Adm.danger)),
        Gap(
          32,
          children: [
            MaxWidth(
              500,
              child: AdmField(
                controller: _search,
                hint: 'Search by name, username, email or user ID',
                fill: Adm.searchFill,
                padLeft: 24.5,
                semanticLabel: 'Search users',
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _debounced = v.trim()));
                  setState(() => _page = 1);
                },
              ),
            ),
            Chips(
              label: 'Filter users',
              items: [for (final f in _filters) ChipItem(f.value, f.label)],
              value: _filter,
              onChanged: (v) => setState(() {
                _filter = v;
                _page = 1;
              }),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(context.dvw(16, 2.1, 40)),
          decoration: BoxDecoration(
            color: Dak.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Dak.border),
          ),
          child: Gap(
            32,
            children: [
              ScrollTable(
                minWidth: 784,
                builder: (width) {
                  final widths = trackWidths(width, _columns);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 23),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Dak.muted.withValues(alpha: .5))),
                        ),
                        child: TrackRow(
                          widths: widths,
                          cells: [
                            for (final h in const ['User', 'User ID', 'Type', 'Status', 'Reports', 'Last Active', 'Action'])
                              Text(h, style: _cellStyle),
                          ],
                        ),
                      ),
                      if (error != null)
                        StateText(errorMessage(error), error: true, center: true, padY: 48)
                      else if (data == null)
                        const StateText('Loading…', center: true, padY: 48)
                      else if (data.items.isEmpty)
                        const StateText('No users match these filters.', center: true, padY: 48)
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Gap(
                            27,
                            children: [for (final u in data.items) _UserRow(user: u, widths: widths)],
                          ),
                        ),
                    ],
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Dak.muted.withValues(alpha: .5))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total Users:', style: _cellStyle),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Dak.muted),
                          ),
                          child: Text(
                            formatNumber(data?.total ?? 0),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -.2, color: Dak.muted),
                          ),
                        ),
                      ],
                    ),
                    PagerButtons(page: _page, pages: data?.pages ?? 1, loaded: data != null, onPage: (p) => setState(() => _page = p)),
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

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.widths});

  final AdminUserRow user;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final label = accountStatusLabel[user.status] ?? user.status;
    return TrackRow(
      widths: widths,
      cells: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Avatar(src: user.avatarUrl, name: user.name),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -.2, color: Dak.heading),
                    ),
                    const SizedBox(height: 8),
                    Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: _cellStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(user.displayId, maxLines: 1, overflow: TextOverflow.ellipsis, style: _cellStyle),
        ),
        Text(accountTypeLabel(user.accountType), style: _cellStyle),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusBadge(label: label, tone: accountStatusTone(label)),
        ),
        Text('${user.reports}', style: _cellStyle),
        Text(timeAgo(user.lastActiveAt), softWrap: false, overflow: TextOverflow.visible, style: _cellStyle),
        AdmButton(
          label: 'See Details',
          onTap: () => context.go('/users/${user.id}'),
          fill: Dak.cta,
          height: 40,
          width: 110,
          radius: 24,
          padX: 8,
          fontSize: 14,
          letterSpacing: .28,
        ),
      ],
    );
  }
}

/// The Previous / Next pair at the bottom of the users table.
class PagerButtons extends StatelessWidget {
  const PagerButtons({super.key, required this.page, required this.pages, required this.onPage, this.loaded = true});

  final int page;
  final int pages;
  final bool loaded;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = loaded && page < pages;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hover(
          builder: (context, hovered) => AdmButton(
            label: 'Previous',
            onTap: canPrev ? () => onPage(page - 1) : null,
            border: Dak.muted,
            color: canPrev && hovered ? Dak.heading : Dak.muted,
            radius: 30,
            padX: 24,
            weight: FontWeight.w600,
            letterSpacing: -.2,
            disabledOpacity: 1,
          ),
        ),
        const SizedBox(width: 24),
        AdmButton(
          label: 'Next',
          onTap: canNext ? () => onPage(page + 1) : null,
          fill: Dak.cta,
          width: 116,
          radius: 30,
          padX: 24,
          weight: FontWeight.w600,
          letterSpacing: -.2,
        ),
      ],
    );
  }
}
