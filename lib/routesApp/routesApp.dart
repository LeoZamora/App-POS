import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:inversiones_ar/screens/mainScreen.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/services/stateServices.dart';
import '../login/loginApp.dart';

GoRouter crearRouter(BuildContext context) {
  final authServices = Provider.of<StateServices>(context, listen: false);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authServices,

    redirect: (BuildContext context, GoRouterState state) {
      if (!authServices.isInitialized) return null;

      final bool logueado = authServices.isAuthenticated;
      final bool enPantallaLogin = state.matchedLocation == '/login';

      if (!logueado && !enPantallaLogin) {
        return '/login';
      }

      if (logueado && enPantallaLogin) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const InicioScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => LoginApp(),
      )
    ],
  );
}