// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulpiprint_program/features/auth/data/auth_repository.dart';
import '../../../products/presentation/providers/product_providers.dart'; // Para reutilizar el supabaseProvider

// 1. Provider del Repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthRepository(client);
});

// 2. Provider del Usuario Actual (Reactivo)
final authUserProvider = StreamProvider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// 3. Controller de Login (Maneja la acción de loguearse)
class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  LoginController(this._repository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signIn(email: email, password: password));
  }
  
  Future<void> logout() async {
    await _repository.signOut();
  }
}

// 4. Provider del Controller
final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginController(repository);
});