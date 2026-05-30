import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'features/notification/data/services/notification_service.dart';
import 'core/services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Notifications
  final notifSvc = NotificationService();
  await notifSvc.init();
  await notifSvc.scheduleDailyReminder();
  await notifSvc.scheduleWeeklyReminder();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp();
  }

  // FORCE CLEAR CACHE - TO FIX CursorWindow NO_MEMORY
  await FirebaseFirestore.instance.clearPersistence();

  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);

  // Restore saved primary colour
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getInt(AppConstants.keyPrimaryColor);
  if (saved != null) AppTheme.setPrimary(Color(saved));

  // Restore saved language
  final langCode = await LanguageService().getLanguage();
  
  runApp(HermonaApp(
    initialDark: prefs.getBool(AppConstants.keyThemeMode) ?? false,
    initialLocale: Locale(langCode),
  ));
}

class HermonaApp extends StatefulWidget {
  final bool initialDark;
  final Locale initialLocale;
  const HermonaApp({super.key, required this.initialDark, required this.initialLocale});

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
    _locale = widget.initialLocale;
  }

  void setThemeMode(ThemeMode m) => setState(() => _mode = m);
  void setPrimaryColor(Color c) => setState(() {
    AppTheme.setPrimary(c);
  });
  void setLocale(Locale l) {
    debugPrint("DEBUG AUDIT: HermonaAppState.setLocale called with ${l.languageCode}");
    setState(() => _locale = l);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG AUDIT: MaterialApp REBUILDING with locale = ${_locale?.languageCode}");
    debugPrint("DEBUG AUDIT: MATERIALAPP LOCALE = $_locale");
    debugPrint("DEBUG AUDIT: SUPPORTED LOCALES = [fr, en]");

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
