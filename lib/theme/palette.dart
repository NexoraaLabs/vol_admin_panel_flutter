import 'package:flutter/painting.dart';

/// The colour themes an admin can pick. Default is the original VÔL look; the other three keep
/// accents and status colours apart for colour-blind people (Okabe-Ito based) or low vision.
enum ColorTheme {
  standard('Default', 'Original VÔL purple', _standard),
  redGreen('Red-green safe', 'Protanopia and deuteranopia', _redGreen),
  blueYellow('Blue-yellow safe', 'Tritanopia', _blueYellow),
  highContrast('High contrast', 'Pure black, white text, stronger borders', _highContrast);

  const ColorTheme(this.label, this.hint, this.palette);

  final String label;
  final String hint;
  final Palette palette;

  static ColorTheme parse(String? name) => values.firstWhere((t) => t.name == name, orElse: () => standard);
}

class Palette {
  const Palette({
    this.bg = const Color(0xFF050505),
    this.heading = const Color(0xFFF4F4F6),
    this.body = const Color(0xFFC8CBD0),
    this.cta = const Color(0xFF9436FB),
    this.ctaDeep = const Color(0xFF582095),
    this.muted = const Color(0xFF777A82),
    this.line = const Color(0xFFC793FF),
    this.surface = const Color(0xFF121212),
    this.border = const Color(0xFF2B2B31),
    this.sidebar = const Color(0xFF0F090C),
    this.sidebarLine = const Color(0xFFC793FF),
    this.logout = const Color(0xFF1D1D20),
    this.logoutBorder = const Color(0xFFB86E9F),
    this.inputBorder = const Color(0xFF636365),
    this.placeholder = const Color(0xFFCECECE),
    this.tooltip = const Color(0xFF2B2B2B),
    this.tooltipBorder = const Color(0xFFB4B4B4),
    this.success = const Color(0xFF23C54E),
    this.warning = const Color(0xFFFBBC05),
    this.danger = const Color(0xFFE5252E),
    this.dangerText = const Color(0xFFC5221F),
    this.dangerDark = const Color(0xFFA5121A),
    this.chipBorder = const Color(0xFFD9D9D9),
    this.blue = const Color(0xFF4285F4),
    this.searchFill = const Color(0xFF0B0F19),
    this.slate = const Color(0xFF31384A),
    this.policyRow = const Color(0xFF111520),
    this.rowHover = const Color(0xFF161616),
    this.successFill = const Color(0xFF0A2312),
    this.warningFill = const Color(0xFF2A2306),
    this.dangerFill = const Color(0xFF2A0D0E),
    this.infoFill = const Color(0xFF0D1A2F),
    this.activity = const [Color(0xFF3C6EF7), Color(0xFF00B5E7), Color(0xFF3BCC92), Color(0xFFE0BC4B)],
    this.activityTips = const [Color(0xFF3C6EF7), Color(0xFF00B5E7), Color(0xFF23C54E), Color(0xFFE0BC4B)],
    this.series = const [Color(0xFF4285F4), Color(0xFFFBBC05), Color(0xFF3BCC92), Color(0xFF9436FB), Color(0xFFEA4335)],
  });

  final Color bg, heading, body, cta, ctaDeep, muted, line, surface, border;
  final Color sidebar, sidebarLine, logout, logoutBorder, inputBorder, placeholder, tooltip, tooltipBorder;
  final Color success, warning, danger, dangerText, dangerDark, chipBorder, blue;
  final Color searchFill, slate, policyRow, rowHover;
  final Color successFill, warningFill, dangerFill, infoFill;

  /// Workspaces, canvases, classrooms, catalog.
  final List<Color> activity;

  /// Tooltip text for the same series. Figma shows classrooms in a different green from its bar.
  final List<Color>? activityTips;

  /// Donut and other multi-series charts, in order.
  final List<Color> series;
}

const _standard = Palette();

// Blue and orange instead of green and red.
const _redGreen = Palette(
  cta: Color(0xFF0072B2),
  ctaDeep: Color(0xFF004A75),
  line: Color(0xFF56B4E9),
  sidebar: Color(0xFF080D12),
  sidebarLine: Color(0xFF56B4E9),
  logoutBorder: Color(0xFF56B4E9),
  success: Color(0xFF56B4E9),
  warning: Color(0xFFF0E442),
  danger: Color(0xFFD55E00),
  dangerText: Color(0xFFE8792A),
  dangerDark: Color(0xFFA04500),
  blue: Color(0xFFCC79A7),
  successFill: Color(0xFF0B1D27),
  warningFill: Color(0xFF26240A),
  dangerFill: Color(0xFF2A1405),
  infoFill: Color(0xFF26131F),
  activityTips: null,
  activity: [Color(0xFF0072B2), Color(0xFF56B4E9), Color(0xFFE69F00), Color(0xFFCC79A7)],
  series: [Color(0xFF0072B2), Color(0xFFE69F00), Color(0xFF56B4E9), Color(0xFFCC79A7), Color(0xFFD55E00)],
);

// Teal and red, no blue against green or yellow against pink.
const _blueYellow = Palette(
  cta: Color(0xFF00796B),
  ctaDeep: Color(0xFF004D40),
  line: Color(0xFF4DB6AC),
  sidebar: Color(0xFF07100F),
  sidebarLine: Color(0xFF4DB6AC),
  logoutBorder: Color(0xFF4DB6AC),
  success: Color(0xFF4DD0C4),
  warning: Color(0xFFFF8A65),
  danger: Color(0xFFE53935),
  dangerText: Color(0xFFEF5350),
  dangerDark: Color(0xFFB71C1C),
  blue: Color(0xFFF48FB1),
  successFill: Color(0xFF0A2422),
  warningFill: Color(0xFF2A1610),
  dangerFill: Color(0xFF2A0D0E),
  infoFill: Color(0xFF2A1520),
  activityTips: null,
  activity: [Color(0xFF00897B), Color(0xFFD81B60), Color(0xFF80CBC4), Color(0xFFFF8A65)],
  series: [Color(0xFF00897B), Color(0xFFD81B60), Color(0xFF80CBC4), Color(0xFFFF8A65), Color(0xFFB0BEC5)],
);

// The accent is the one blue that reads on black and under white text.
const _highContrast = Palette(
  bg: Color(0xFF000000),
  heading: Color(0xFFFFFFFF),
  body: Color(0xFFFFFFFF),
  cta: Color(0xFF2F6BFF),
  ctaDeep: Color(0xFF1A47C2),
  muted: Color(0xFFCFCFCF),
  line: Color(0xFFFFE500),
  surface: Color(0xFF0A0A0A),
  border: Color(0xFF8A8A8A),
  sidebar: Color(0xFF000000),
  sidebarLine: Color(0xFFFFFFFF),
  logout: Color(0xFF0A0A0A),
  logoutBorder: Color(0xFFFFFFFF),
  inputBorder: Color(0xFFBDBDBD),
  placeholder: Color(0xFFE0E0E0),
  tooltip: Color(0xFF000000),
  tooltipBorder: Color(0xFFFFFFFF),
  success: Color(0xFF00E5FF),
  warning: Color(0xFFFFE500),
  danger: Color(0xFFFF5C5C),
  dangerText: Color(0xFFFF8A8A),
  dangerDark: Color(0xFFC00000),
  chipBorder: Color(0xFFFFFFFF),
  blue: Color(0xFF8AB4FF),
  searchFill: Color(0xFF000000),
  slate: Color(0xFF8A8A8A),
  policyRow: Color(0xFF0A0A0A),
  rowHover: Color(0xFF1F1F1F),
  successFill: Color(0xFF002A30),
  warningFill: Color(0xFF262300),
  dangerFill: Color(0xFF2A0000),
  infoFill: Color(0xFF0A1430),
  activityTips: null,
  activity: [Color(0xFF2F6BFF), Color(0xFFFFE500), Color(0xFFFFFFFF), Color(0xFFFF6EC7)],
  series: [Color(0xFF2F6BFF), Color(0xFFFFE500), Color(0xFF00E5FF), Color(0xFFFF6EC7), Color(0xFFFFFFFF)],
);
