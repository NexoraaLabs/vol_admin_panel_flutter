import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

// Widgets style themselves to match the web classes, so the theme only sets fonts and base colours.
// Inter is the body font, as in apps/admin; Geist is applied where the web uses font-heading.
ThemeData adminTheme() {
  const colors = ColorScheme.dark(
    primary: Dak.cta,
    onPrimary: Colors.white,
    surface: Dak.surface,
    onSurface: Dak.heading,
    outline: Dak.border,
  );
  final base = ThemeData(colorScheme: colors, scaffoldBackgroundColor: Dak.bg, splashFactory: NoSplash.splashFactory);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: Dak.heading, displayColor: Dak.heading),
    textSelectionTheme: TextSelectionThemeData(selectionColor: Dak.cta.withValues(alpha: .3), cursorColor: Dak.heading),
  );
}

/// Geist, the web's `font-heading`.
TextStyle heading(TextStyle style) => GoogleFonts.geist(textStyle: style);

/// Small uppercase Geist title used by the Figma detail cards.
TextStyle cardTitleStyle([Color color = Dak.heading]) =>
    heading(TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: 1.4, color: color));
