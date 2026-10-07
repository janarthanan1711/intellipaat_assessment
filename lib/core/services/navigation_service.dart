import 'package:flutter/widgets.dart';

/// Navigation from outside the widget tree (e.g. the network layer forcing
/// a logout when the session expires).
class NavigationService {
  final navigatorKey = GlobalKey<NavigatorState>();

  void resetTo(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}
