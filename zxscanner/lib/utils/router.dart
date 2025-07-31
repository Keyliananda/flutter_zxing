import 'package:flutter/material.dart';
import '../pages/creator_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/scanner_page.dart';
import '../pages/settings_page.dart';
import '../pages/camera_test_page.dart';

abstract class AppRoutes {
  static const String creator = '/creator';
  static const String history = '/history';
  static const String home = '/';
  static const String scanner = '/scanner';
  static const String settings = '/settings';
  static const String cameraTest = '/camera-test';
}

class AppRouter {
  Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.creator:
        return MaterialPageRoute<void>(
          builder: (_) => const CreatorPage(),
        );
      case AppRoutes.history:
        return MaterialPageRoute<void>(
          builder: (_) => const HistoryPage(),
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
        );
      case AppRoutes.scanner:
        return MaterialPageRoute<void>(
          builder: (_) => const ScannerPage(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsPage(),
        );
      case AppRoutes.cameraTest:
        return MaterialPageRoute<void>(
          builder: (_) => const CameraTestPage(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => Container(),
        );
    }
  }
}
