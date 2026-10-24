// Non-web builds (tests) have no sessionStorage or downloads.
final _session = <String, String>{};

String? sessionGet(String key) => _session[key];

void sessionSet(String key, String value) => _session[key] = value;

void sessionRemove(String key) => _session.remove(key);

void downloadText(String filename, String text, String mimeType) {}
