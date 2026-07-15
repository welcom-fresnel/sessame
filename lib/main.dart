import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'services/database_factory_initializer.dart';
import 'services/firebase_web_config.dart';
import 'providers/project_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/gamification_provider.dart';
import 'screens/splash_screen.dart'; // Importation du SplashScreen
import 'screens/auth_screen.dart'; // Importation de l'AuthScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      try {
        final uri = Uri.base.resolve('firebase_config.json');
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final cfg = json.decode(resp.body) as Map<String, dynamic>;
          FirebaseWebConfig.googleClientId = cfg['googleClientId']?.toString();
          final options = FirebaseOptions(
            apiKey: (cfg['apiKey'] ?? '').toString(),
            authDomain: (cfg['authDomain'] ?? '').toString(),
            projectId: (cfg['projectId'] ?? '').toString(),
            storageBucket: (cfg['storageBucket'] ?? '').toString(),
            messagingSenderId: (cfg['messagingSenderId'] ?? '').toString(),
            appId: (cfg['appId'] ?? '').toString(),
            measurementId: (cfg['measurementId'] ?? '').toString(),
          );
          await Firebase.initializeApp(options: options);
        } else {
          // Fallback to default initialize (may fail if no native config)
          await Firebase.initializeApp();
        }
      } catch (e) {
        print('⚠️ Firebase web init failed: $e');
      }
    } else {
      await Firebase.initializeApp();
    }

    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      print('⚠️ Firebase Analytics init skipped: $e');
    }

    // If the app was redirected back from an OAuth redirect (web), try to
    // resolve the redirect result so the sign-in completes.
    if (kIsWeb) {
      try {
        final result = await FirebaseAuth.instance.getRedirectResult();
        if (result.user != null) {
          print('✅ Firebase redirect sign-in completed for ${result.user!.uid}');
        }
      } catch (e) {
        print('⚠️ getRedirectResult failed: $e');
      }
    }
  } catch (e) {
    // If Firebase isn't configured for a platform, keep the app running.
    print('⚠️ Firebase init skipped: $e');
  }

  await initializeDatabaseFactory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PremiumProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => GamificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final provider = ProjectProvider();
            // Fire and forget initialization (don't block UI)
            provider.initialize().catchError((e) {
              print('❌ ProjectProvider initialization error: $e');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final provider = ConversationProvider();
            // Fire and forget initialization
            provider.initialize().catchError((e) {
              print('❌ ConversationProvider initialization error: $e');
            });
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Asala - Suivi de Projets',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[50],
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
            locale: const Locale('fr', 'FR'),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
