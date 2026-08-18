import 'package:flutter/material.dart';

enum AppTransition { push, fade, slideUp }

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    AppTransition transition = AppTransition.push,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            switch (transition) {
              case AppTransition.fade:
                return FadeTransition(opacity: curved, child: child);
              case AppTransition.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
              case AppTransition.push:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
            }
          },
        );
}

extension AppNavigation on BuildContext {
  Future<T?> pushPage<T>(Widget page, {AppTransition transition = AppTransition.push}) {
    return Navigator.of(this).push<T>(AppPageRoute<T>(page: page, transition: transition));
  }

  Future<T?> pushReplacementPage<T extends Object?>(Widget page, {AppTransition transition = AppTransition.fade}) {
    return Navigator.of(this).pushReplacement<T, void>(
      AppPageRoute<T>(page: page, transition: transition),
    );
  }
}
