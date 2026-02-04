import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'providers/playlist_provider.dart';
import 'providers/glossary_provider.dart';
import 'providers/player_provider.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.songsBox);
  await Hive.openBox(AppConstants.glossaryBox);
  await Hive.openBox(AppConstants.settingsBox);

  // Warm up TTS early to avoid first-utterance accent issues (especially on Web).
  try {
    await TtsService().init();
  } catch (_) {
    // Ignore TTS init errors at startup.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => GlossaryProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
