import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:inversiones_ar/screens/mainScreen.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/services/stateServices.dart';
import '../login/loginApp.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final authServices = Provider.of<StateServices>(context, listen: false);
    final isLogin = authServices.isLoading;
    final isLoginScreen = state.path == '/login';

    if(!isLogin && !isLoginScreen) {
      return '/login';
    } else if(isLogin && isLoginScreen) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const InicioScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return LoginApp();
      }
    )
  ]
);