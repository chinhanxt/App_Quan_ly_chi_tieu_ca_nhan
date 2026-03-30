import 'dart:math' as math;

import 'package:flutter/material.dart';

class MobileAdaptive {
  const MobileAdaptive._();

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isShortHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 760;

  static bool isLargeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) > 16.1;

  static bool useCompactLayout(BuildContext context) =>
      isCompactWidth(context) || isShortHeight(context) || isLargeText(context);

  static EdgeInsets safeContentPadding(
    BuildContext context, {
    double horizontal = 16,
    double top = 0,
    double bottom = 0,
  }) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottom +
          math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom),
    );
  }
}
