import 'package:flutter/painting.dart';

// Copied from packages/ui/src/tokens.css and apps/admin/src/app/globals.css. Keep the names in sync.
abstract final class Dak {
  static const bg = Color(0xFF050505);
  static const heading = Color(0xFFF4F4F6);
  static const body = Color(0xFFC8CBD0);
  static const cta = Color(0xFF9436FB);
  static const muted = Color(0xFF777A82);
  static const line = Color(0xFFC793FF);
  static const surface = Color(0xFF121212);
  static const border = Color(0xFF2B2B31);
}

// The admin panel is dark-only, so these have no light counterparts.
abstract final class Adm {
  static const sidebar = Color(0xFF0F090C);
  static const sidebarLine = Color(0xFFC793FF);
  static const logout = Color(0xFF1D1D20);
  static const logoutBorder = Color(0xFFB86E9F);
  static const inputBorder = Color(0xFF636365);
  static const placeholder = Color(0xFFCECECE);
  static const tooltip = Color(0xFF2B2B2B);
  static const tooltipBorder = Color(0xFFB4B4B4);
  static const success = Color(0xFF23C54E);
  static const warning = Color(0xFFFBBC05);
  static const danger = Color(0xFFE5252E);
  static const dangerText = Color(0xFFC5221F);
  static const dangerDark = Color(0xFFA5121A);
  static const chipBorder = Color(0xFFD9D9D9);
  static const blue = Color(0xFF4285F4);

  // Hard-coded hex values the admin screens use directly.
  static const searchFill = Color(0xFF0B0F19);
  static const slate = Color(0xFF31384A);
  static const policyRow = Color(0xFF111520);
  static const rowHover = Color(0xFF161616);
}
