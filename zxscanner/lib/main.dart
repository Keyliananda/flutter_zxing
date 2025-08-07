
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'configs/app_store.dart';
import 'configs/auth_store.dart';
import 'configs/sync_store.dart';
import 'configs/app_theme.dart';
import 'configs/constants.dart';
import 'generated/l10n.dart' as loc;
import 'utils/db_service.dart';
import 'utils/api_service.dart';
import 'utils/auth_service.dart';
import 'utils/sync_service.dart';
import 'utils/extensions.dart';
import 'utils/router.dart';
import 'utils/scroll_behavior.dart';
import 'utils/shared_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializePrefs();
  await DbService.instance.initializeApp();
  
  // Initialize services
  ApiService.instance.initialize();
  await AuthService.instance.initialize();
  await authStore.initialize();
  await SyncService.instance.initialize();
  await syncStore.initialize();
  
  // Temporarily disabled due to FFI binding issue
  // zx.setLogEnabled(kDebugMode);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => MaterialApp(
        title: appName,
        theme: AppTheme.flexLightTheme(),
        darkTheme: AppTheme.flexDarkTheme(),
        themeMode: appStore.themeMode,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          loc.S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: loc.S.delegate.supportedLocales,
        locale: appStore.selectedLanguage.parseLocale(),
        onGenerateRoute: _appRouter.onGenerateRoute,
        initialRoute: authStore.isAuthenticated ? '/' : '/login',
        scrollBehavior: MyCustomScrollBehavior(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
