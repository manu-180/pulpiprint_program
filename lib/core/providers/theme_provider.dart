// lib/core/providers/theme_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Provider para la instancia de SharedPreferences.
// Lanzamos un error por defecto porque lo vamos a "sobreescribir" en el main.dart
// Esto es Inyección de Dependencias pura: permite testear fácilmente.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// 2. Notifier que gestiona el Tema (Lógica + Estado)
final isDarkModeProvider = NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<bool> {
  static const _key = 'isDarkMode';

  @override
  bool build() {
    // Al iniciar, leemos la preferencia guardada.
    // Si es nula, por defecto es false (Modo Claro).
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  // Método para cambiar y guardar
  void toggle() {
    state = !state; // Cambiamos el estado en memoria (Reactivo)
    ref.read(sharedPreferencesProvider).setBool(_key, state); // Guardamos en disco
  }
}