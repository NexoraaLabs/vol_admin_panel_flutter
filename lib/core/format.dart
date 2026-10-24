// Display helpers, ported from packages/api-client/src/format.ts.

const _units = [(60.0, 's'), (60.0, 'min'), (24.0, 'h'), (7.0, 'd'), (4.35, 'w'), (12.0, 'mo')];

/// "12min ago", "3d ago", "just now".
String timeAgo(DateTime? date) {
  if (date == null) return 'never';
  var value = DateTime.now().difference(date).inMilliseconds / 1000;
  if (value < 45) return 'just now';
  for (final (size, unit) in _units) {
    if (value < size) return '${value.floor()}$unit ago';
    value /= size;
  }
  return '${value.floor()}y ago';
}

/// 1431 -> "1,431".
String formatNumber(num n) {
  final digits = n.round().abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String formatDate(DateTime? date) => date == null ? '—' : date.toUtc().toIso8601String().substring(0, 10);

/// "John Smith" -> "JS".
String initials(String name) => name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

/// "COLLABORATOR" -> "Collaborator".
String titleCase(String s) => s.isEmpty ? s : s[0] + s.substring(1).toLowerCase().replaceAll('_', ' ');

/// 7 -> "07", as the Figma counters show.
String pad2(num n) => '$n'.padLeft(2, '0');

String greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
}
