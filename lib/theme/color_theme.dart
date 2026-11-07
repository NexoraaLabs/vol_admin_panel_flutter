import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'palette.dart';
import 'tokens.dart';

// Overridden in main() once SharedPreferences has loaded.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final colorThemeProvider = NotifierProvider<ColorThemeNotifier, ColorTheme>(ColorThemeNotifier.new);

const _key = 'vol-admin-palette';

/// Applies the saved theme before the first frame, so nothing paints in the wrong colours.
void restoreColorTheme(SharedPreferences prefs) => usePalette(ColorTheme.parse(prefs.getString(_key)).palette);

class ColorThemeNotifier extends Notifier<ColorTheme> {
  @override
  ColorTheme build() => ColorTheme.parse(ref.read(prefsProvider).getString(_key));

  void select(ColorTheme theme) {
    if (theme == state) return;
    usePalette(theme.palette);
    state = theme;
    ref.read(prefsProvider).setString(_key, theme.name);
    _rebuildAll();
  }
}

// Widgets read the tokens directly rather than through an InheritedWidget, so nothing depends on
// the palette. Marking every element dirty repaints them without losing any state.
void _rebuildAll() {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}
