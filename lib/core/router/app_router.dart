// lib/core/router/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/products/presentation/screens/reorder_products_screen.dart'; // Import nuevo

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = Supabase.instance.client.auth.currentSession;
  final initialRoute = session != null ? '/' : '/login';

  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const ProductsScreen(),
        routes: [
          // Ruta para reordenar
          GoRoute(
            path: 'reorder',
            builder: (context, state) => const ReorderProductsScreen(),
          ),
          GoRoute(
            path: 'product/:id',
            builder: (context, state) {
              final idStr = state.pathParameters['id'];
              final productId = (idStr == 'new') ? null : int.tryParse(idStr ?? '');
              return ProductFormScreen(productId: productId);
            },
          ),
        ],
      ),
    ],
  );
});