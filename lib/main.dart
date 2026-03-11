import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/database_factory_initializer.dart';
import 'providers/project_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart'; // Importation du SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            title: 'Sessame - Suivi de Projets',
            debugShowCheckedModeBanner: false,
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

