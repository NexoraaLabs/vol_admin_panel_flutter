import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'admin_user.dart';

// Overridden in main() with a client that has already tried to restore the session.
final apiProvider = Provider<ApiClient>((ref) => throw UnimplementedError());

final authProvider = NotifierProvider<AuthNotifier, AdminUser?>(AuthNotifier.new);

class AuthNotifier extends Notifier<AdminUser?> {
  @override
  AdminUser? build() {
    final api = ref.watch(apiProvider);
    api.onUserChanged = (user) => state = user;
    ref.onDispose(() => api.onUserChanged = null);
    return api.user;
  }
}
