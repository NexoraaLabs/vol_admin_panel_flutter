import 'dart:js_interop';

import 'package:web/web.dart' as web;

// Storage can throw in private windows or with site data blocked; callers treat that as empty.
String? sessionGet(String key) {
  try {
    return web.window.sessionStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void sessionSet(String key, String value) {
  try {
    web.window.sessionStorage.setItem(key, value);
  } catch (_) {}
}

void sessionRemove(String key) {
  try {
    web.window.sessionStorage.removeItem(key);
  } catch (_) {}
}

/// Saves [text] as a file, the Blob + <a download> trick the Next.js panel uses.
void downloadText(String filename, String text, String mimeType) {
  final blob = web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  a.click();
  web.URL.revokeObjectURL(url);
}
