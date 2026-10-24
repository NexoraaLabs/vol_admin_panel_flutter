import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth.dart';
import 'core/env.dart';
import 'core/query.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'ui/layout.dart';
import 'ui/toast.dart';

Future<void> main() async {
  usePathUrlStrategy();

  // Restore the session before the first frame so the router never flashes the login screen.
  final api = ApiClient(apiUrl);
  await api.refresh();

  runApp(ProviderScope(overrides: [apiProvider.overrideWithValue(api)], child: const AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Drop cached responses on sign-out so the next account never sees the last one's data.
    ref.listen(authProvider, (before, now) {
      if (before != null && now == null) invalidateQueries(ref);
    });

    return MaterialApp.router(
      title: 'VÔL Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => FigmaZoom(child: ToastHost(child: child!)),
    );
  }
}
