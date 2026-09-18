import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/dbModels/models_type.dart';
import 'package:inversiones_ar/features/auth/models/authState.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'ihEc.9TNJtihHZ';
  static const _cajaKey = 'ihEc-caja-key';
  static const _cajaStatusKey = "ihEc-cajaStatus-key";
  static const _aperturaCajaKey = 'ihEc-aperturaCaja-key';

  Future<void> checkAuthStatus() async {
    print('ESTAMOS HACIENDO CHECK');
    try {
      final token = await _storage.read(key: _tokenKey);
      final isCajaOpenStr = await _storage.read(key: _cajaKey);

      bool isCajaOpenLocal = isCajaOpenStr == 'true';

      print('TOKEN $token');

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
        );

        print('SIN SESION');
        logout();
        return;
      }

      final jwt = JWT.decode(token);

      if (jwt.payload['exp'] != null) {
        final exp = DateTime.fromMillisecondsSinceEpoch(jwt.payload['exp'] * 1000);
        if (exp.isBefore(DateTime.now())) {
          await _storage.delete(key: _tokenKey);
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            token: null,
            userPayload: null,
            isCajaOpen: false,
            idCajaOpen: 0,
            permisos: []
          );

          logout();
          return;
        }
      }

      int? idCaja = state.idCajaOpen;
      if (idCaja == 0) {
        final idCajaStr = await _storage.read(key: _cajaStatusKey);
        if (idCajaStr != null) {
          idCaja = int.tryParse(idCajaStr);
        }
      }

      final idUsuario = jwt.payload['idusuario'];
      final Map<String, dynamic> statusCaja = await getCajaActiva(idUsuario);

      final String permisosStr = jwt.payload['permisos']?.toString() ?? '';
      final List<int> permisosList = permisosStr.isNotEmpty
          ? permisosStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList()
          : [];


      if (statusCaja.isNotEmpty && statusCaja["tieneAperturaActiva"] == true) {
        final List<CajaModel> cajas = await getCajas(idUsuario);

        final int idCajaActiva = statusCaja['apertura']['idCaja'];

        final cajaLocal = cajas.firstWhere((caja) => caja.idCaja == idCajaActiva, orElse: () => cajas.first);

        print('CAJA LOCAL: $cajaLocal');

        if (cajaLocal.idCaja == 0 || cajaLocal.idCaja.isNaN) {
          await _storage.delete(key: _cajaKey);
          await _storage.delete(key: _cajaStatusKey);

          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            userPayload: TokenPayload.fromMap(jwt.payload),
            isCajaOpen: false,
            permisos: permisosList
          );
        } else {
          final idCajaLocal = statusCaja['apertura']['idCaja'];
          final idAperturaCajaLocal = statusCaja['apertura']['idAperturaCaja'];

          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            userPayload: TokenPayload.fromMap(jwt.payload),
            isCajaOpen: true,
            idCajaOpen: idCajaLocal,
            idAperturaCaja: idAperturaCajaLocal,
            permisos: permisosList
          );
        }

      } else {
        await _storage.delete(key: _cajaKey);
        await _storage.delete(key: _cajaStatusKey);

        state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            userPayload: TokenPayload.fromMap(jwt.payload),
            isCajaOpen: false,
            permisos: permisosList
        );
      }

    } catch (e, stackTrace) {
      print('ERROR: $e');
      print('STACKTRACE: $stackTrace');
      // await _storage.delete(key: _tokenKey);
      return logout();
    }
  }

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  AuthState build() {
    Future.microtask(
          () => checkAuthStatus(),
    );

    return AuthState(
      status: AuthStatus.checking,
    );
  }

  Future<void> login(String tokenStr) async {
    try {
      await _storage.write(key: _tokenKey, value: tokenStr);
      final jwt = JWT.decode(tokenStr);
      final idUsuario = jwt.payload['idusuario'];

      final String permisosStr = jwt.payload['permisos']?.toString() ?? '';
      final List<int> permisosList = permisosStr.isNotEmpty
          ? permisosStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList()
          : [];

      bool cajaAbiertaLocal = false;
      int idCajaLocal = 0;
      int? idAperturaCajaLocal = 0;

      final Map<String, dynamic> statusCaja = await getCajaActiva(idUsuario);

      if (statusCaja.isNotEmpty && statusCaja["tieneAperturaActiva"] == true) {
        cajaAbiertaLocal = true;
        idCajaLocal = statusCaja['apertura']['idCaja'];
        idAperturaCajaLocal = statusCaja['apertura']['idAperturaCaja'];

        state = state.copyWith(
            status: AuthStatus.authenticated,
            token: tokenStr,
            userPayload: TokenPayload.fromMap(jwt.payload),
            isCajaOpen: cajaAbiertaLocal,
            idCajaOpen: idCajaLocal,
            idAperturaCaja: idAperturaCajaLocal,
            permisos: permisosList
        );
      } else {
        await _storage.delete(key: _cajaKey);
        await _storage.delete(key: _cajaStatusKey);

        state = state.copyWith(
            status: AuthStatus.authenticated,
            token: tokenStr,
            userPayload: TokenPayload.fromMap(jwt.payload),
            isCajaOpen: false,
            permisos: permisosList
        );
      }

      print('Login exitoso: ${state.toString()}');

    } catch (e, stackTrace) {
      print('Error crítico en login: $e');
      print('Stacktrace: $stackTrace');
      logout();
    }
  }

  Future<void> checkCajaStatus() async {
    try {
      final cajaStatus = await _storage.read(key: _cajaKey);
      state = state.copyWith(isCajaOpen: cajaStatus == 'true');
    } catch (e) {
      logout();
    }
  }

  Future<void> restoreSession() async {
    try {
      state = state.copyWith(
        status: AuthStatus.checking,
      );

      final token = await _storage.read(key: _tokenKey);

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
        );
        return;
      }

      final jwt = JWT.decode(token);

      // Verificar expiración
      final exp = jwt.payload['exp'];

      if (exp != null) {
        final expiration = DateTime.fromMillisecondsSinceEpoch(
          (exp as int) * 1000,
        );

        if (DateTime.now().isAfter(expiration)) {
          await logout();

          state = state.copyWith(
            status: AuthStatus.unauthenticated,
          );

          return;
        }
      }

      final idUsuario = jwt.payload['idusuario'];

      final String permisosStr =
          jwt.payload['permisos']?.toString() ?? '';

      final List<int> permisosList = permisosStr.isNotEmpty
          ? permisosStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList()
          : [];

      bool cajaAbiertaLocal = false;
      int idCajaLocal = 0;
      int idAperturaCajaLocal = 0;

      // Restaurar información de caja
      final cajaStatus = await _storage.read(
        key: _cajaKey,
      );

      final cajaId = await _storage.read(
        key: _cajaStatusKey,
      );

      final aperturaId = await _storage.read(
        key: _aperturaCajaKey,
      );

      if (cajaStatus == 'true' && cajaId != null) {
        cajaAbiertaLocal = true;
        idCajaLocal = int.tryParse(cajaId) ?? 0;
        idAperturaCajaLocal =
            int.tryParse(aperturaId ?? '') ?? 0;
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userPayload: TokenPayload.fromMap(jwt.payload),
        isCajaOpen: cajaAbiertaLocal,
        idCajaOpen: idCajaLocal,
        idAperturaCaja: idAperturaCajaLocal,
        permisos: permisosList,
      );

      print('Sesión restaurada');
      print(state);

    } catch (e, stackTrace) {
      print('Error restaurando sesión: $e');
      print(stackTrace);

      await logout();

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  Future<void> initializeAuth() async {
    try {
      state = state.copyWith(
        status: AuthStatus.checking,
      );

      final token = await _storage.read(
        key: _tokenKey,
      );

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
        );
        return;
      }

      // Restaurar usuario/token
      final jwt = JWT.decode(token);

      final idUsuario = jwt.payload['idusuario'];

      final permisosStr =
          jwt.payload['permisos']?.toString() ?? '';

      final permisos = permisosStr.isNotEmpty
          ? permisosStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList()
          : <int>[];

      // Restaurar caja
      final cajaIdStr = await _storage.read(
        key: _cajaStatusKey,
      );

      final aperturaIdStr = await _storage.read(
        key: _aperturaCajaKey,
      );

      final idCaja = int.tryParse(
        cajaIdStr ?? '',
      ) ?? 0;

      final idAperturaCaja = int.tryParse(
        aperturaIdStr ?? '',
      ) ?? 0;

      final isCajaOpen =
          idCaja > 0 &&
              idAperturaCaja > 0;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userPayload: TokenPayload.fromMap(
          jwt.payload,
        ),
        isCajaOpen: isCajaOpen,
        idCajaOpen: idCaja,
        idAperturaCaja: idAperturaCaja,
        permisos: permisos,
      );

    } catch (e, stackTrace) {
      print('Error inicializando autenticación: $e');
      print(stackTrace);

      await _storage.delete(
        key: _tokenKey,
      );

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  Future<void> _bootstrapAuth() async {
    // 1) Restauración rápida (token, permisos, idAperturaCaja) sin red.
    await initializeAuth();

    // 2) Si quedó autenticado y con una caja registrada localmente,
    //    confirmamos contra el servidor que esa apertura sigue abierta
    //    (por si se cerró desde otro dispositivo, por ejemplo).
    if (state.status == AuthStatus.authenticated && state.idCajaOpen != 0) {
      await checkAuthStatus();
    }
  }

  Future<void> setAperturaCaja(int idAperturaCaja) async {
    await _storage.write(key: _aperturaCajaKey, value: idAperturaCaja.toString());
    state = state.copyWith(idAperturaCaja: idAperturaCaja);
  }

  Future<void> openCaja(int idCaja) async {
    try {
      await Future.wait([
        _storage.write(key: _cajaKey, value: 'true'),
        _storage.write(key: _cajaStatusKey, value: idCaja.toString())
      ]);

      state = state.copyWith(
          status: AuthStatus.authenticated,
          isCajaOpen: true,
          idCajaOpen: idCaja,
      );
    } catch (e) {
      logout();
    }
  }

  Future<bool> checkStatusCaja(int idCaja) async {
    try {
      final response = await getAperturaCaja(idCaja);

      final bool isCajaOpen = response.estado == true;

      await _storage.write(key: _cajaKey, value: isCajaOpen.toString());

      state = state.copyWith(isCajaOpen: isCajaOpen, idCajaOpen: idCaja);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> closeCaja() async {
    try {
      await _storage.delete(key: _cajaKey);
      state = state.copyWith(
        isCajaOpen: false,
        idCajaOpen: 0,
        idAperturaCaja: 0,
        permisos: [],
      );
    } catch (e) {
      logout();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});