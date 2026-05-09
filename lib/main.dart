import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp();
  }

  await initializeDateFormatting('fr', null);

  // Restore saved primary colour
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getInt(AppConstants.keyPrimaryColor);
  if (saved != null) AppTheme.setPrimary(Color(saved));

  runApp(HermonaApp(
    initialDark: prefs.getBool(AppConstants.keyThemeMode) ?? false,
  ));
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class HermonaApp extends StatefulWidget {
  final bool initialDark;
  const HermonaApp({super.key, required this.initialDark});

  static HermonaAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<HermonaAppState>();

  @override
  State<HermonaApp> createState() => HermonaAppState();
}

class HermonaAppState extends State<HermonaApp> {
  late ThemeMode _mode;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode m) => setState(() => _mode = m);
  void setLocale(Locale l) => setState(() => _locale = l);

  @override
  Widget build(BuildContext context) {
    debugPrint('build: HermonaApp');
    return MaterialApp.router(
      title: 'HERMONA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      locale: _locale,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
      ],
    );
  }
}

