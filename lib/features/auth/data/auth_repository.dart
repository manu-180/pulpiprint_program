// lib/features/auth/data/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // Iniciar Sesión
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // Supabase lanza AuthException para errores de login
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión');
    }
  }

  // Cerrar Sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _client.auth.currentUser;
  
  // Stream de estado de autenticación (para redirigir si se desconecta)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}