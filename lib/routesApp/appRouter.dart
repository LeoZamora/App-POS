import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';

import 'package:inversiones_ar/screens/mainScreen.dart';
import 'package:inversiones_ar/login/loginApp.dart';
import 'package:inversiones_ar/screens/screenCaja.dart';
import 'package:inversiones_ar/screens/screenPedidoById.dart';
import 'package:inversiones_ar/screens/sreenRetiroEfectivo.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../features/auth/models/authState.dart';

class DesgloseEfectivo {
  final int denominacion;
  final int cantidad;

  DesgloseEfectivo({required this.denominacion, required this.cantidad});

  double get subtotal => (denominacion * cantidad).toDouble();
}
final RouteObserver<ModalRoute<void>> routerObserver = RouteObserver<ModalRoute<void>>();

class SplashScreen extends StatelessWidget {
  final String message;

  const SplashScreen({
    super.key,
    this.message = 'Cargando...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.threeArchedCircle(color: Colors.indigo, size: 40),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (prev, next) {
        if(prev?.status != next.status || prev?.isCajaOpen != next.isCajaOpen) {
          notifyListeners();
        }
      }
    );
  }
}

final routesProvider = Provider<GoRouter>((ref) {
  // final authState = ref.watch(authProvider);
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    observers: [routerObserver],
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
        final authState = ref.read(authProvider);

        final status = authState.status;
        final isCajaOpen = authState.isCajaOpen;

        final isChecking = status == AuthStatus.checking;
        final isAuth = status == AuthStatus.authenticated;

        final isGoingToSplash = state.matchedLocation == '/splash';
        final isGoingToLogin = state.matchedLocation == '/login';

        final isGoingToAbrirCaja = state.matchedLocation == '/caja/false';
        final isGoingToCerrarCaja = state.matchedLocation == '/caja/true';
        final isGoingToCaja = isGoingToAbrirCaja || isGoingToCerrarCaja;

        print('ROUTE DE GO ${state.matchedLocation}');

        // 1. Mientras verifica token/sesión, mantener en Splash
        if (isChecking) {
          return isGoingToSplash ? null : '/splash';
        }

        // 2. Si NO está autenticado, mandarlo a Login
        if (!isAuth) {
          return isGoingToLogin ? null : '/login';
        }

        // --- A PARTIR DE AQUÍ EL USUARIO SÍ ESTÁ AUTENTICADO ---

        // 3. Si no ha abierto caja: solo puede estar en /caja/false (abrir).
        //    Cualquier otro intento -> lo mandamos a abrir caja.
        if (!isCajaOpen) {
          return isGoingToAbrirCaja ? null : '/caja/false';
        }

        // 4. Si la caja SÍ está abierta:
        //    - No tiene sentido volver a Login, Splash o a "abrir caja" -> Home
        //    - Pero SÍ puede ir deliberadamente a "cerrar caja" -> dejarlo pasar
        if (isGoingToLogin || isGoingToSplash || isGoingToAbrirCaja) {
          return '/';
        }

        // 5. Dejar navegar libremente en las demás rutas (incluye /caja/true)
        return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) => SplashScreen(message: 'Cargando...',)
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const InicioScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginApp(),
      ),
      // GoRoute(
      //   path: '/caja',
      //   builder: (BuildContext context, GoRouterState state) => const CajaScreen(),
      // ),
      GoRoute(
        path: '/retiro-efectivo',
        builder: (BuildContext context, GoRouterState state) => EgresosCapitalScreen(),
      ),
      GoRoute(
        path: '/pedido/:id',
        builder: (context, state) {
          // Extraemos el parámetro de la URL
          final idString = state.pathParameters['id'];
          final idPedido = int.tryParse(idString ?? '0') ?? 0;

          // Y se lo pasamos al constructor del widget
          return PedidoById(idPedido: idPedido);
        },
      ),
      GoRoute(
        path: '/caja/:isCierre',
        builder: (context, state) {
          // Extraemos el parámetro de la URL
          final idString = state.pathParameters['isCierre'];
          final isCierreCaja = bool.tryParse(idString ?? 'false') ?? false;

          // Y se lo pasamos al constructor del widget
          return CajaScreen(isCierre: isCierreCaja);
        },
      ),
    ]
  );
});