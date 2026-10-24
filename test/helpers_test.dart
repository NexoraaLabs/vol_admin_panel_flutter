import 'package:flutter_test/flutter_test.dart';
import 'package:vol_admin/charts/chart_theme.dart';
import 'package:vol_admin/core/query.dart';
import 'package:vol_admin/models/admin.dart';
import 'package:vol_admin/ui/layout.dart';
import 'package:vol_admin/ui/widgets.dart';

void main() {
  test('growth ticks follow the 1-2-5 steps above the peak', () {
    expect(growthTicks(0), [0, 1, 2, 5, 10]);
    expect(growthTicks(14), [0, 2, 4, 10, 20]);
    expect(growthTicks(73000), [0, 10000, 20000, 50000, 100000]);
  });

  test('values sit between evenly spaced tick positions', () {
    const ticks = [0, 10, 20, 50, 100];
    expect(tickPosition(ticks, 0), 0);
    expect(tickPosition(ticks, 15), 1.5);
    expect(tickPosition(ticks, 35), 2.5);
    expect(tickPosition(ticks, 500), 4);
  });

  test('axis labels shorten thousands', () {
    expect(formatK(500), '500');
    expect(formatK(10000), '10k');
    expect(formatK(2500), '2.5k');
  });

  test('grid tracks share the space but keep their minimums', () {
    final widths = trackWidths(784, const [(min: 264, fr: 341), (min: 84, fr: 186), (min: 110, fr: 0)]);
    expect(widths[0], greaterThanOrEqualTo(264));
    expect(widths[2], 110);
    expect(widths.reduce((a, b) => a + b), closeTo(784, .001));
  });

  test('query strings skip empty values', () {
    expect(withQuery('/admin/cases', {'status': '', 'q': 'spam', 'page': 2}), '/admin/cases?q=spam&page=2');
    expect(withQuery('/admin/users', {'q': ''}), '/admin/users');
  });

  test('stat cards read deltas and notes', () {
    expect(Stat.of('Users', 'i.svg', 1431, delta: '+8.7%').delta, '+8.7% vs last month');
    expect(Stat.of('Users', 'i.svg', 1431, delta: '-2%').up, isFalse);
    expect(Stat.of('Users', 'i.svg', 1431, note: '40% of users').value, '1,431');
  });

  test('admin responses parse', () {
    final list = AdminCaseList.fromJson({
      'items': [
        {
          'id': 'c1',
          'displayId': 'ESC-0001',
          'title': 'Spam in community',
          'violation': 'Spam',
          'status': 'OPEN',
          'reportedUser': {'id': 'u2', 'name': 'Sam'},
          'reporter': null,
          'assignee': null,
          'reportCount': 3,
          'evidence': ['Screenshot'],
          'escalatedAt': '2026-10-01T10:00:00.000Z',
          'resolvedAt': null,
          'createdAt': '2026-10-01T09:00:00.000Z',
        },
      ],
      'total': 1,
      'page': 1,
      'limit': 10,
      'pages': 1,
      'stats': {'open': 1, 'inReview': 0, 'reopenedThisMonth': 0},
    });
    expect(list.page.items.single.reportedUser.name, 'Sam');
    expect(list.stats.open, 1);

    final dash = AdminDashboard.fromJson({
      'stats': {
        'totalUsers': {'value': 10, 'delta': '+5%'},
      },
      'userGrowth': [
        {'label': 'Jan', 'total': 4, 'active': 2},
      ],
      'businessGrowth': [],
      'activityByWeek': [],
      'health': {'openCriticalCases': 1, 'securityAlerts24h': 0, 'failedAdminLogins24h': 2},
    });
    expect(dash.stat('totalUsers').delta, '+5%');
    expect(dash.stat('bannedUsers').value, 0);
    expect(dash.userGrowth.single['active'], 2);
  });
}
