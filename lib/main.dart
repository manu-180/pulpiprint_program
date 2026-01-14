// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart'; 
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 2. Inicializar Preferencias (Persistencia local)
  final prefs = await SharedPreferences.getInstance();

  // 3. Configuración de Ventana
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800), 
    minimumSize: Size(600, 600), 
    center: true,
    title: 'PulpiPrint Manager',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 4. Inyección de Dependencias (Override)
  // Aquí "sobreescribimos" el provider vacío con la instancia real de prefs
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MainApp(),
  ));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    // Ahora esto lee de memoria y no falla
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'PulpiPrint Manager',
      
      // --- TEMA CLARO ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        fontFamily: 'Fredoka',
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      ),

      // --- TEMA OSCURO ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D4EDD), 
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        fontFamily: 'Fredoka',
        scaffoldBackgroundColor: const Color(0xFF121212), 
        
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF252525),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)
          ),
        ),
      ),
      
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}