import 'package:flutter/material.dart';

/// Responsive breakpoint helpers.
///
/// Usage:
///   Res.isTablet(context)  → true when width ≥ 600
///   Res.padding(context)   → EdgeInsets with responsive horizontal padding
///   Res.cols(context, mobile: 2, tablet: 4)  → grid column count
class Res {
  Res._();

  /// Tablet breakpoint: screens ≥ 600 logical pixels wide.
  static const double kTablet = 600.0;

  /// Max content width – content is centered beyond this.
  static const double kMaxContent = 720.0;

  /// True when screen width ≥ 600 dp (tablet or large-phone landscape).
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= kTablet;

  /// True when the device is in landscape orientation.
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Current screen width in logical pixels.
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Horizontal padding that auto-centers content on large screens.
  static double hp(BuildContext context) {
    final w = width(context);
    if (w > kMaxContent) return (w - kMaxContent) / 2;
    if (w >= kTablet) return 24.0;
    return 16.0;
  }

  /// Standard responsive EdgeInsets (symmetric vertical default 16).
  static EdgeInsets padding(BuildContext context, {double vertical = 16}) =>
      EdgeInsets.fromLTRB(hp(context), vertical, hp(context), vertical);

  /// Grid column count: [mobile] on phones, [tablet] on tablets.
  static int cols(BuildContext context, {int mobile = 2, int tablet = 3}) =>
      isTablet(context) ? tablet : mobile;

  /// Quick-access menu icon columns in the home grid.
  static int menuCols(BuildContext context) => isTablet(context) ? 6 : 4;
}
