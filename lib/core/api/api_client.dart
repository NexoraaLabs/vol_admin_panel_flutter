import 'package:dio/dio.dart';

import '../auth/admin_user.dart';
import 'api_error.dart';
import 'credentials.dart';

/// Talks to apps/api the way packages/api-client does with `scope: "admin"`: sessions use the admin
/// refresh cookie and /auth/admin/* endpoints, so signing in here never touches a user-app session
/// in the same browser. The access token lives in memory and is renewed through that cookie.
class ApiClient {
  ApiClient(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl.replaceAll(RegExp(r'/$'), ''))) {
    sendCookies(_dio);
  }

  static const _authPath = '/auth/admin';

  final Dio _dio;
  String? _token;
  AdminUser? _user;
  Future<AdminUser?>? _refreshing;

  void Function(AdminUser? user)? onUserChanged;

  AdminUser? get user => _user;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);
  Future<T> post<T>(String path, [Object? body]) => _send('POST', path, body: body ?? const {});
  Future<T> put<T>(String path, Object? body) => _send('PUT', path, body: body);

  /// GET a non-JSON response (the users CSV export) as text, with the same auth handling.
  Future<String> text(String path) => _send('GET', path, responseType: ResponseType.plain);

  /// Call with the body of the response that started the session (/auth/admin/verify).
  AdminUser setSession(Map<String, dynamic> session) {
    _token = session['accessToken'] as String;
    final user = AdminUser.fromJson(session['user'] as Map<String, dynamic>);
    _setUser(user);
    return user;
  }

  /// Concurrent callers share one request, otherwise the API would rotate the cookie twice.
  Future<AdminUser?> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> logout() async {
    try {
      await _dio.post<void>('$_authPath/logout');
    } on DioException {
      // Signed out locally either way.
    } finally {
      _token = null;
      _setUser(null);
    }
  }

  Future<AdminUser?> _refresh() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('$_authPath/refresh');
      return setSession(res.data!);
    } on DioException catch (e) {
      // Offline: keep what we have and let the next request try again.
      if (e.response == null) return null;
      _token = null;
      _setUser(null);
      return null;
    }
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    ResponseType? responseType,
    bool retried = false,
  }) async {
    if (_token == null && !retried) await refresh();
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, responseType: responseType, headers: {if (_token != null) 'authorization': 'Bearer $_token'}),
      );
      return res.data as T;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !retried && !path.startsWith('/auth/')) {
        if (await refresh() != null) {
          return _send(method, path, body: body, query: query, responseType: responseType, retried: true);
        }
      }
      throw ApiError.fromDio(e);
    }
  }

  void _setUser(AdminUser? user) {
    _user = user;
    onUserChanged?.call(user);
  }
}
