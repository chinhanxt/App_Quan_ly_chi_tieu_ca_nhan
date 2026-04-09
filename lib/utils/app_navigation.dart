import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<int?> dashboardTabRequest = ValueNotifier<int?>(null);

class DashboardTransactionTarget {
  const DashboardTransactionTarget({
    required this.monthYear,
    required this.category,
    required this.type,
  });

  final String monthYear;
  final String category;
  final String type;
}

final ValueNotifier<DashboardTransactionTarget?>
dashboardTransactionTargetRequest = ValueNotifier<DashboardTransactionTarget?>(
  null,
);

class SmoothCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  SmoothCupertinoPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.title,
    super.fullscreenDialog,
  }) : super(maintainState: true, allowSnapshotting: true);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);
}

Route<T> buildAdaptiveRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  if (!kIsWeb) {
    return SmoothCupertinoPageRoute<T>(builder: builder, settings: settings);
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return SmoothCupertinoPageRoute<T>(builder: builder, settings: settings);
    default:
      return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}

Future<T?> pushAdaptiveScreen<T>(
  BuildContext context,
  Widget screen, {
  RouteSettings? settings,
}) {
  return Navigator.of(
    context,
  ).push<T>(buildAdaptiveRoute<T>(builder: (_) => screen, settings: settings));
}

Future<T?> pushAdaptiveScreenWithNavigator<T>(
  NavigatorState navigator,
  Widget screen, {
  RouteSettings? settings,
}) {
  return navigator.push<T>(
    buildAdaptiveRoute<T>(builder: (_) => screen, settings: settings),
  );
}
