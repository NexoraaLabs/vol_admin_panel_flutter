import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth.dart';

/// Cached GET responses keyed by path, the Flutter side of useApiQuery() in apps/admin.
/// Screens watch `query('/admin/users')` and parse the JSON they get back.
final query = FutureProvider.autoDispose.family<dynamic, String>((ref, path) {
  return ref.watch(apiProvider).get<dynamic>(path);
});

/// Like [query], but refetched every minute while on screen (useApiQuery's refreshInterval: 60_000).
/// The last response stays visible during each refetch.
final polledQuery = FutureProvider.autoDispose.family<dynamic, String>((ref, path) {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(apiProvider).get<dynamic>(path);
});

/// Refetches every query on screen, which covers the web panel's invalidate("/admin/users", ...).
void invalidateQueries(WidgetRef ref) {
  ref.invalidate(query);
  ref.invalidate(polledQuery);
}

/// Builds "/path?a=1&b=2", skipping empty values.
String withQuery(String path, Map<String, Object?> params) {
  final parts = <String>[];
  params.forEach((key, value) {
    if (value == null || value == '') return;
    parts.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('$value')}');
  });
  return parts.isEmpty ? path : '$path?${parts.join('&')}';
}
