import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../charts/activity_chart.dart';
import '../../charts/growth_chart.dart';
import '../../charts/share_donut.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../ui/layout.dart';
import '../../ui/widgets.dart';
import '../dashboard/dashboard_page.dart';
import '../shell/panel_shell.dart';

const _tabs = [ChipItem('growth', 'Growth'), ChipItem('engagement', 'Engagement'), ChipItem('composition', 'Composition')];

// Donut colours from Figma 790:5518, extended for extra business segments.
const _shareColors = [Color(0xFF4285F4), Color(0xFFFBBC05), Color(0xFF3BCC92), Color(0xFF9436FB), Color(0xFFEA4335)];

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  var _tab = 'growth';
  var _period = 'yearly';

  @override
  Widget build(BuildContext context) {
    final json = ref.watch(query('/admin/analytics?period=$_period')).value;
    final data = json == null ? null : AdminAnalytics.fromJson(json as Map<String, dynamic>);
    final dashJson = _tab == 'engagement' ? ref.watch(query('/admin/dashboard')).value : null;
    final dashboard = dashJson == null ? null : AdminDashboard.fromJson(dashJson as Map<String, dynamic>);
    final now = DateTime.now();

    final stats = data == null
        ? <Stat>[]
        : [
            Stat.of('Total Users', 'icons/nav/users.svg', data.totalUsers, note: 'All registered accounts'),
            Stat.of('Active workspaces', 'icons/stats/workspaces.svg', data.activeWorkspaces, note: 'Updated in the last 30 days'),
            Stat.of('Classrooms running', 'icons/stats/classrooms.svg', data.classroomsRunning, note: 'Published'),
            Stat.of('Total products', 'icons/stats/products.svg', data.products, note: 'Published in catalogs'),
          ];

    return PanelPage(
      children: [
        const PageHeader(title: 'Analytics', subtitle: 'Aggregate performance — growth, engagement, content and safety.'),
        GridRows(
          columns: statColumns(context, lgStep: false),
          children: data == null ? [for (var i = 0; i < 4; i++) const PulseBox()] : [for (final s in stats) StatCard(stat: s)],
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chips(label: 'Analytics views', items: _tabs, value: _tab, onChanged: (v) => setState(() => _tab = v)),
            if (_tab == 'growth')
              Chips(
                label: 'Growth period',
                items: const [ChipItem('yearly', 'Yearly'), ChipItem('monthly', 'Monthly')],
                value: _period,
                onChanged: (v) => setState(() => _period = v),
              ),
          ],
        ),
        MaxWidth(
          800,
          child: switch (_tab) {
            'engagement' => Panel(
              title: 'Workspace, canvas, classroom & catalog activity',
              period: 'Monthly',
              child: dashboard == null ? const SizedBox(height: 236) : ActivityChart(data: dashboard.activityByWeek),
            ),
            'composition' => Panel(
              title: 'Account composition',
              subtitle: 'Share of platform accounts by type',
              child: data == null
                  ? const SizedBox(height: 290)
                  : ShareDonut(
                      data: [
                        for (final (i, s) in data.accountShare.indexed) DonutSlice(s.name, s.value, _shareColors[i % _shareColors.length]),
                      ],
                    ),
            ),
            _ => Panel(
              title: 'User & business growth',
              subtitle: 'Cumulative accounts and active users',
              period: _period == 'yearly' ? 'Yearly' : 'Monthly',
              child: data == null
                  ? const SizedBox(height: 236)
                  : GrowthChart(
                      key: ValueKey(_period),
                      data: data.growth,
                      defaultIndex: _period == 'yearly' ? now.month - 1 : now.day - 1,
                      series: const [
                        GrowthSeries(key: 'total', label: 'Total User', color: Color(0xFF9436FB), stroke: GrowthStroke.progress),
                        GrowthSeries(key: 'active', label: 'Active User', color: Color(0xFF4285F4)),
                      ],
                    ),
            ),
          },
        ),
      ],
    );
  }
}
