import 'package:flutter/painting.dart';

import 'palette.dart';

// Names copied from packages/ui/src/tokens.css and apps/admin/src/app/globals.css. Keep them in sync.
// Values come from the active colour theme, see palette.dart and color_theme.dart.
Palette _p = ColorTheme.standard.palette;

void usePalette(Palette palette) => _p = palette;

abstract final class Dak {
  static Color get bg => _p.bg;
  static Color get heading => _p.heading;
  static Color get body => _p.body;
  static Color get cta => _p.cta;
  static Color get ctaDeep => _p.ctaDeep;
  static Color get muted => _p.muted;
  static Color get line => _p.line;
  static Color get surface => _p.surface;
  static Color get border => _p.border;
}

// The admin panel is dark-only, so these have no light counterparts.
abstract final class Adm {
  static Color get sidebar => _p.sidebar;
  static Color get sidebarLine => _p.sidebarLine;
  static Color get logout => _p.logout;
  static Color get logoutBorder => _p.logoutBorder;
  static Color get inputBorder => _p.inputBorder;
  static Color get placeholder => _p.placeholder;
  static Color get tooltip => _p.tooltip;
  static Color get tooltipBorder => _p.tooltipBorder;
  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get danger => _p.danger;
  static Color get dangerText => _p.dangerText;
  static Color get dangerDark => _p.dangerDark;
  static Color get chipBorder => _p.chipBorder;
  static Color get blue => _p.blue;

  // Opaque status tints for toasts and badges.
  static Color get successFill => _p.successFill;
  static Color get warningFill => _p.warningFill;
  static Color get dangerFill => _p.dangerFill;
  static Color get infoFill => _p.infoFill;

  static List<Color> get activity => _p.activity;
  static List<Color> get activityTips => _p.activityTips ?? _p.activity;
  static List<Color> get series => _p.series;

  // Hard-coded hex values the admin screens use directly.
  static Color get searchFill => _p.searchFill;
  static Color get slate => _p.slate;
  static Color get policyRow => _p.policyRow;
  static Color get rowHover => _p.rowHover;
}
