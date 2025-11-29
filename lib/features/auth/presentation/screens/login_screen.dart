// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Necesario para navegar
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pulpiprint_program/features/products/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();

  
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Llamamos al controller de Riverpod para iniciar sesión
    await ref.read(loginControllerProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. ESCUCHAMOS CAMBIOS DE ESTADO (Efectos secundarios)
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      // Si hay error, mostramos SnackBar
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Si terminó con éxito (no está cargando y no tiene error)
      if (!next.isLoading && !next.hasError) {
        context.go('/'); // Navegamos al Dashboard
      }
    });

    // 2. OBSERVAMOS EL ESTADO PARA LA UI (Loading)
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // --- IZQUIERDA: PANEL DE MARCA ---
          Expanded(
            child: Container(
              color: colorScheme.primaryContainer,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/pulpiprint_program.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PulpiPrint\nManager',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- DERECHA: FORMULARIO ---
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bienvenido de nuevo',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus credenciales para continuar.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 48),

                        // Input Email
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading, // Deshabilitar si carga
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(LucideIcons.mail),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requerido';
                            if (!value.contains('@')) return 'Email no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // <--- USA LA VARIABLE AQUÍ
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(LucideIcons.lock),
                      // --- AQUÍ ESTÁ EL CAMBIO PRINCIPAL ---
                      suffixIcon: IconButton(
                        // Cambia el icono según el estado
                        icon: Icon(
                          _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey.shade600,
                        ),
                        // Al presionar, invierte el estado y redibuja
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      // ------------------------------------
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),

                        // Botón de Login
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Ingresar', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}