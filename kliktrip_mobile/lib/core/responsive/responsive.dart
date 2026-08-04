import 'package:flutter/material.dart';

class Responsive {
  static const double _mobile = 480;
  static const double _tablet = 768;
  static const double _desktop = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobile &&
      MediaQuery.of(context).size.width < _desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktop;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double scale(BuildContext context) {
    final w = width(context);
    if (w > _tablet) return 1.25;
    if (w > _mobile) return 1.1;
    return 1.0;
  }

  static double fontSize(BuildContext context, double size) =>
      size * scale(context);

  static double horizontalPadding(BuildContext context) =>
      isMobile(context) ? 16 : (isTablet(context) ? 24 : 32);

  static double verticalPadding(BuildContext context) =>
      isMobile(context) ? 16 : 24;

  static EdgeInsets screenPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: horizontalPadding(context),
        vertical: verticalPadding(context),
      );

  static double cardWidth(BuildContext context) {
    if (isDesktop(context)) return width(context) * 0.45;
    if (isTablet(context)) return width(context) * 0.48;
    return double.infinity;
  }

  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Lebar konten maksimal agar tidak melebar penuh di tablet/desktop
  /// (gaya konten tiket.com: tetap terpusat & rapi).
  static const double contentMaxWidth = 720;

  /// Membungkus [child] agar konten terpusat dengan lebar maksimal
  /// [contentMaxWidth] pada layar lebar.
  static Widget constrainWidth(
    Widget child, {
    double maxWidth = contentMaxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static double iconSize(BuildContext context, double base) =>
      base * scale(context);

  static double buttonHeight(BuildContext context) =>
      isMobile(context) ? 48 : 56;

  static Widget horizontalSpacing(double amount) =>
      SizedBox(width: amount);

  static Widget verticalSpacing(double amount) =>
      SizedBox(height: amount);
}
