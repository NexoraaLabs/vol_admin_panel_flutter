import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../charts/activity_chart.dart';
import '../../charts/growth_chart.dart';
import '../../core/auth/auth.dart';
import '../../core/format.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/tokens.dart';
import '../../ui/layout.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

/// Stat grid: 1 / 2 (sm) / 3 (lg) / 4 (xl) columns.
int statColumns(BuildContext context, {bool lgStep = true}) => context.isXl ? 4 : (context.isLg && lgStep ? 3 : (context.isSm ? 2 : 1));

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final json = ref.watch(polledQuery('/admin/dashboard')).value;
    final data = json == null ? null : AdminDashboard.fromJson(json as Map<String, dynamic>);
    final month = DateTime.now().month - 1;

    String share(String key) {
      final total = data!.stat('totalUsers').value;
      return '${(data.stat(key).value / (total < 1 ? 1 : total) * 100).round()}% of users';
    }

    final stats = data == null
        ? <Stat>[]
        : [
            Stat.of('Total Users', 'icons/nav/users.svg', data.stat('totalUsers').value, delta: data.stat('totalUsers').delta),
            Stat.of('Individual Users', 'icons/stats/user.svg', data.stat('individualUsers').value, note: share('individualUsers')),
            Stat.of('Business Users', 'icons/stats/business-users.svg', data.stat('businessUsers').value, note: share('businessUsers')),
            Stat.of(
              'Active Users (30d)',
              'icons/stats/activity.svg',
              data.stat('activeUsers30d').value,
              delta: data.stat('activeUsers30d').delta,
            ),
            Stat.of(
              'New Registrations (7d)',
              'icons/stats/user-plus.svg',
              data.stat('newRegistrations7d').value,
              note: '${data.stat('newRegistrations7d').delta} vs last week',
            ),
            Stat.of('Total Workspaces', 'icons/stats/workspaces.svg', data.stat('workspaces').value, delta: data.stat('workspaces').delta),
            Stat.of('Total Classrooms', 'icons/stats/classrooms.svg', data.stat('classrooms').value, delta: data.stat('classrooms').delta),
            Stat.of('Total Catalogs', 'icons/stats/catalogs.svg', data.stat('catalogs').value, delta: data.stat('catalogs').delta),
            Stat.of('Total Canvases', 'icons/stats/canvases.svg', data.stat('canvases').value, delta: data.stat('canvases').delta),
            Stat.of(
              'Suspended Users',
              'icons/stats/user-minus.svg',
              data.stat('suspendedUsers').value,
              note: '+${data.stat('suspendedUsers').thisWeek ?? 0} this week',
              up: false,
            ),
            Stat.of(
              'Banned Users',
              'icons/stats/banned.svg',
              data.stat('bannedUsers').value,
              note: '+${data.stat('bannedUsers').thisWeek ?? 0} this week',
              up: false,
            ),
          ];

    final health = data == null
        ? <(String, int, Color)>[]
        : [
            ('Open critical cases', data.health.openCriticalCases, Adm.dangerText),
            ('Security alerts (24 h)', data.health.securityAlerts24h, Adm.warning),
            ('Failed admin logins (24 h)', data.health.failedAdminLogins24h, Adm.warning),
          ];

    return PanelPage(
      children: [
        PageHeader(
          eyebrow: 'Dashboard Overview',
          title: '${greeting()}, ${user?.name.split(' ').first ?? ''}.',
          actions: [
            AdmButton(
              label: 'Open Cases',
              onTap: () => context.go('/cases'),
              icon: 'icons/case.svg',
              iconSize: 24,
              fill: Dak.cta,
              color: Colors.white,
              height: 56,
              width: 170,
              radius: 12,
              weight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ],
        ),
        GridRows(
          columns: statColumns(context),
          children: data == null ? [for (var i = 0; i < 8; i++) const PulseBox()] : [for (final s in stats) StatCard(stat: s)],
        ),
        SplitRow(
          left: Panel(
            title: 'User Growth',
            period: 'Yearly',
            child: data == null
                ? const SizedBox(height: 236)
                : GrowthChart(
                    data: data.userGrowth,
                    defaultIndex: month,
                    series: const [
                      GrowthSeries(key: 'total', label: 'Total User', color: Color(0xFF9436FB), stroke: GrowthStroke.progress),
                      GrowthSeries(key: 'active', label: 'Active User', color: Color(0xFF4285F4)),
                    ],
                  ),
          ),
          right: Panel(
            title: 'Business Growth',
            period: 'Monthly',
            child: data == null
                ? const SizedBox(height: 236)
                : GrowthChart(
                    data: data.businessGrowth,
                    defaultIndex: data.businessGrowth.isEmpty ? 0 : data.businessGrowth.length - 1,
                    series: const [
                      GrowthSeries(
                        key: 'business',
                        label: 'Business',
                        color: Color(0xFF9436FB),
                        accent: Color(0xFF23C54E),
                        stroke: GrowthStroke.dashed,
                      ),
                    ],
                  ),
          ),
        ),
        SplitRow(
          left: Panel(
            title: 'Workspace, canvas, classroom & catalog activity',
            period: 'Monthly',
            child: data == null ? const SizedBox(height: 236) : ActivityChart(data: data.activityByWeek),
          ),
          right: Panel(
            title: 'Platform health',
            child: Gap(
              24,
              children: [
                for (final (label, value, color) in health)
                  Pressable(
                    onTap: () => context.go(label.startsWith('Open') ? '/cases' : '/security'),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Dak.border,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Dak.muted),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -.3, color: Dak.body),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(30)),
                            child: Text(
                              '$value',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -.3, color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
