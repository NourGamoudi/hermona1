import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

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

  runApp(AcneIAApp(
    initialDark: prefs.getBool(AppConstants.keyThemeMode) ?? false,
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
class AcneIAApp extends StatefulWidget {
  final bool initialDark;
  const AcneIAApp({super.key, required this.initialDark});

  static _AcneIAAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AcneIAAppState>();

  @override
  State<AcneIAApp> createState() => _AcneIAAppState();
}

class _AcneIAAppState extends State<AcneIAApp> {
  late ThemeMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode m) => setState(() => _mode = m);

  @override
  Widget build(BuildContext context) {
    print('build: AcneIAApp');
    return MaterialApp.router(
      title: 'HERMONA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      routerConfig: appRouter,
    );
  }
}
