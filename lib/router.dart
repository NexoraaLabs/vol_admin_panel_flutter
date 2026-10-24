import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/admin_user.dart';
import 'core/auth/auth.dart';
import 'features/analytics/analytics_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/verify_page.dart';
import 'features/cases/case_detail_page.dart';
import 'features/cases/cases_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/policies/policy_editor.dart';
import 'features/security/security_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/panel_shell.dart';
import 'features/users/user_detail_page.dart';
import 'features/users/users_page.dart';

/// Only same-site paths are followed after sign-in.
String safeNext(String? next) => next != null && next.startsWith('/') && !next.startsWith('//') ? next : '/dashboard';

/// Mirrors RequireAdmin and the login page's "already signed in" redirect in apps/admin.
String? redirectFor(AdminUser? user, Uri uri) {
  final path = uri.path;
  final staff = user?.isStaff ?? false;
  if (path == '/') return staff ? '/dashboard' : '/login';
  if (path == '/login') return staff ? '/dashboard' : null;
  if (path == '/verify') return null;
  if (!staff) return Uri(path: '/login', queryParameters: {'next': uri.toString()}).toString();
  return null;
}

typedef _Params = Map<String, String>;

GoRoute _page(String path, Widget Function(_Params params, _Params query) build) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: build(state.pathParameters, state.uri.queryParameters)),
);

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier<AdminUser?>(ref.read(authProvider));
  ref.listen(authProvider, (_, user) => signedIn.value = user);
  ref.onDispose(signedIn.dispose);

  return GoRouter(
    refreshListenable: signedIn,
    redirect: (_, state) => redirectFor(ref.read(authProvider), state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      _page('/login', (_, q) => LoginPage(next: q['next'])),
      _page('/verify', (_, q) => VerifyPage(email: q['email'] ?? '', next: safeNext(q['next']))),
      ShellRoute(
        builder: (_, state, child) => PanelShell(location: state.uri.path, child: child),
        routes: [
          _page('/dashboard', (_, _) => const DashboardPage()),
          // Keyed on the query so a new top-bar search resets the table's local search state.
          _page('/users', (_, q) => UsersPage(key: ValueKey(q['q'] ?? ''), initialQuery: q['q'] ?? '')),
          _page('/users/:id', (p, q) => UserDetailPage(id: p['id']!, tab: userTabs.contains(q['tab']) ? q['tab']! : 'profile')),
          _page('/cases', (_, _) => const CasesPage()),
          _page('/cases/:id', (p, _) => CaseDetailPage(id: p['id']!)),
          _page('/analytics', (_, _) => const AnalyticsPage()),
          _page('/security', (_, _) => const SecurityPage()),
          _page('/terms', (_, _) => const PolicyEditor(key: ValueKey('terms'), title: 'Terms & Conditions', type: 'terms')),
          _page('/privacy', (_, _) => const PolicyEditor(key: ValueKey('privacy'), title: 'Privacy Policy', type: 'privacy')),
          _page('/settings', (_, q) => SettingsPage(tab: q['tab'] ?? 'overview')),
        ],
      ),
    ],
  );
});
