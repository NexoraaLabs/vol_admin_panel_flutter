import 'package:flutter_test/flutter_test.dart';
import 'package:vol_admin/core/auth/admin_user.dart';
import 'package:vol_admin/router.dart';

AdminUser user(String role) => AdminUser(id: 'u1', name: 'Ana Admin', email: 'a@b.co', role: role);

String? go(AdminUser? me, String location) => redirectFor(me, Uri.parse(location));

void main() {
  test('signed-out visitors are sent to login and brought back', () {
    expect(go(null, '/users'), '/login?next=%2Fusers');
    expect(go(null, '/users/abc?tab=workspaces'), '/login?next=%2Fusers%2Fabc%3Ftab%3Dworkspaces');
    expect(go(null, '/login'), isNull);
    expect(go(null, '/'), '/login');
  });

  test('the verify screen is open to everyone', () {
    expect(go(null, '/verify?email=a@b.co'), isNull);
    expect(go(user('ADMIN'), '/verify'), isNull);
  });

  test('staff skip the login screen', () {
    expect(go(user('ADMIN'), '/login'), '/dashboard');
    expect(go(user('MODERATOR'), '/'), '/dashboard');
    expect(go(user('MODERATOR'), '/cases'), isNull);
  });

  test('signed-in members who are not staff cannot open the panel', () {
    expect(go(user('USER'), '/dashboard'), '/login?next=%2Fdashboard');
    expect(go(user('USER'), '/login'), isNull);
  });

  test('only same-site paths are followed after sign-in', () {
    expect(safeNext('/cases/ESC-0001'), '/cases/ESC-0001');
    expect(safeNext('//evil.example'), '/dashboard');
    expect(safeNext('https://evil.example'), '/dashboard');
    expect(safeNext(null), '/dashboard');
  });
}
