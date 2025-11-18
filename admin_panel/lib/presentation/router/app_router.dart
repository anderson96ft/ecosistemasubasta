import 'dart:async'; // <-- 2. AÑADIDO PARA StreamSubscription

import 'package:admin_panel/features/auth/bloc/auth_bloc.dart'; // <-- 1. RUTA CORREGIDA
import 'package:admin_panel/features/dashboard/presentation/screens/home_screen.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:admin_panel/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      // --- AÑADIMOS LA RUTA DEL DASHBOARD ---
      GoRoute(
        path: '/dashboard',
        builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
      ),
      // La ruta '/home' ya no es necesaria si el dashboard es la pantalla principal.
      // Podrías eliminarla o mantenerla si tiene otro propósito.
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // --- LÓGICA DE REDIRECCIÓN CORREGIDA ---
      final bool loggedIn = authBloc.state.status == AuthStatus.authenticated && authBloc.state.isAdmin;
      final bool loggingIn = state.matchedLocation == '/login';

      // Si no está logueado como admin, debe ir al login.
      if (!loggedIn) return '/login';
      
      // Si está logueado como admin y trata de ir al login, llévalo al DASHBOARD.
      if (loggedIn && loggingIn) return '/dashboard';

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
