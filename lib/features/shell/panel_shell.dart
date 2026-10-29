import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';
import '../../ui/modals.dart';
import '../../ui/widgets.dart';

const _navItems = [
  (href: '/dashboard', label: 'Dashboard', icon: 'dashboard'),
  (href: '/users', label: 'User Management', icon: 'users'),
  (href: '/cases', label: 'Cases', icon: 'cases'),
  (href: '/analytics', label: 'Analytics', icon: 'analytics'),
  (href: '/security', label: 'Security Center', icon: 'security'),
  (href: '/terms', label: 'Terms & Conditions', icon: 'terms'),
  (href: '/privacy', label: 'Privacy Policies', icon: 'privacy'),
  (href: '/settings', label: 'System Settings', icon: 'settings'),
];

/// The (panel) layout: fixed sidebar on desktop (a slide-in drawer below lg), fixed top bar, and
/// the page scrolling underneath.
class PanelShell extends ConsumerStatefulWidget {
  const PanelShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends ConsumerState<PanelShell> {
  var _sidebarOpen = false;

  Future<void> _logout() async {
    setState(() => _sidebarOpen = false);
    if (!await showSignOutModal(context)) return;
    await ref.read(apiProvider).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isLg;
    final sidebarW = context.sidebarWidth;
    final barH = desktop ? 100.0 : 80.0;

    return Scaffold(
      backgroundColor: Dak.bg,
      body: Stack(
        children: [
          Positioned.fill(left: desktop ? sidebarW : 0, child: widget.child),
          Positioned(
            left: desktop ? sidebarW : 0,
            right: 0,
            top: 0,
            height: barH,
            child: _TopNav(onMenu: () => setState(() => _sidebarOpen = true)),
          ),
          if (!desktop && _sidebarOpen)
            Positioned.fill(
              child: Semantics(
                label: 'Close menu',
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarOpen = false),
                  child: Container(color: Colors.black.withValues(alpha: .6)),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            width: desktop ? sidebarW : (context.screenWidth * .85).clamp(0, 300),
            left: desktop || _sidebarOpen ? 0 : -(context.screenWidth * .85).clamp(0, 300) - 1,
            child: _Sidebar(location: widget.location, onNavigate: () => setState(() => _sidebarOpen = false), onLogout: _logout),
          ),
        ],
      ),
    );
  }
}

/// Every panel page: scrolls under the top bar with the panel's padding around a 24px-gap column.
class PanelPage extends StatelessWidget {
  const PanelPage({super.key, required this.children, this.gap = 24});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final desktop = context.isLg;
    final padX = context.isSm ? 24.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(desktop ? 50 : padX, desktop ? 140 : 96, desktop ? 51 : padX, 40),
      child: Gap(gap, children: children),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.onNavigate, required this.onLogout});

  final String location;
  final VoidCallback onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final desktop = context.isLg;
    final padX = desktop ? (context.screenWidth * .0361 - 29.3).clamp(16.0, 40.0) : 16.0;
    final labelSize = context.dvw(16, 1.05, 20);
    final activeH = context.dvh(40, 5.2, 56);

    return Container(
      decoration: const BoxDecoration(
        color: Adm.sidebar,
        border: Border(right: BorderSide(color: Adm.sidebarLine)),
        boxShadow: [BoxShadow(color: Color(0x809436FB), offset: Offset(0, 64), blurRadius: 64, spreadRadius: -32)],
      ),
      child: Column(
        children: [
          // Figma: logo frame 80px from the top, 142px tall (90×136 logo), then 30px to the first link.
          SizedBox(height: context.dvh(12, 7.4, 80)),
          SizedBox(
            height: context.dvh(56, 13.15, 142),
            child: Center(
              child: SizedBox(
                height: context.dvh(52, 12.6, 136),
                child: const AssetIcon('brand/admin-logo.png'),
              ),
            ),
          ),
          SizedBox(height: context.dvh(12, 2.78, 30)),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: padX),
                children: [
                  for (final (i, item) in _navItems.indexed) ...[
                    if (i > 0) SizedBox(height: context.dvh(4, 2.2, 24)),
                    _NavLink(
                      label: item.label,
                      icon: 'icons/nav/${item.icon}.svg',
                      active: location == item.href || location.startsWith('${item.href}/'),
                      activeHeight: activeH,
                      idleHeight: context.dvh(34, 4.45, 48),
                      fontSize: labelSize,
                      onTap: () {
                        onNavigate();
                        context.go(item.href);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(padX, context.dvh(8, 1.5, 16), padX, context.dvh(12, 4.6, 50)),
            child: Pressable(
              onTap: onLogout,
              child: Container(
                height: activeH,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Adm.logout,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Adm.logoutBorder, width: .5),
                ),
                child: Row(
                  children: [
                    const AssetIcon('icons/nav/logout.svg', width: 24, height: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w500, letterSpacing: .28, color: Dak.heading),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeHeight,
    required this.idleHeight,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool active;
  final double activeHeight;
  final double idleHeight;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hover(
      builder: (context, hovered) => Pressable(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: active ? activeHeight : idleHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: !active && hovered ? Colors.white.withValues(alpha: .05) : null,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment(-.98, -.22),
                    end: Alignment(.98, .22),
                    stops: [.0057, 1],
                    colors: [Color(0xFF9436FB), Color(0xFF582095)],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? Dak.cta : Colors.transparent),
          ),
          child: Row(
            children: [
              AssetIcon(icon, width: 24, height: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: .28, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNav extends ConsumerStatefulWidget {
  const _TopNav({required this.onMenu});

  final VoidCallback onMenu;

  @override
  ConsumerState<_TopNav> createState() => _TopNavState();
}

class _TopNavState extends ConsumerState<_TopNav> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final q = value.trim();
    context.go(q.isEmpty ? '/users' : Uri(path: '/users', queryParameters: {'q': q}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    // The bell shows how many reports are waiting for a moderator.
    final json = ref.watch(polledQuery('/admin/cases?limit=1')).value;
    final stats = json is Map<String, dynamic> && json['stats'] != null ? CaseStats.fromJson(json['stats'] as Map<String, dynamic>) : null;
    final waiting = (stats?.open ?? 0) + (stats?.inReview ?? 0);
    final desktop = context.isLg;

    return Container(
      color: Dak.bg,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 40 : (context.isSm ? 24 : 16)),
      child: Row(
        children: [
          if (!desktop) ...[
            Pressable(
              onTap: widget.onMenu,
              label: 'Open menu',
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        Container(width: 20, height: 2, color: Dak.heading),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: AdmField(
                  controller: _search,
                  hint: 'Search users, businesses..',
                  height: 41,
                  padRight: 16,
                  semanticLabel: 'Search',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 10.5),
                    child: AssetIcon('icons/search.svg', width: 18, height: 18),
                  ),
                  onSubmitted: _submit,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: waiting > 0 ? '$waiting open cases' : 'Cases',
            child: Pressable(
              onTap: () => context.go('/cases'),
              label: waiting > 0 ? '$waiting open cases' : 'Cases',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Padding(padding: EdgeInsets.all(4), child: AssetIcon('icons/bell.svg', width: 16, height: 20)),
                  if (waiting > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: Dak.cta, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          waiting > 9 ? '9+' : '$waiting',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1.6, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: user != null ? '${user.name} · ${user.email}' : 'Admin account',
            child: Avatar(src: user?.avatarUrl, name: user?.name ?? '', size: 42, fallbackAsset: 'brand/admin-avatar.png'),
          ),
        ],
      ),
    );
  }
}
