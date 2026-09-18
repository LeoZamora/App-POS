import 'package:inversiones_ar/dbModels/dbModels.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final TokenPayload? userPayload;
  final bool isCajaOpen;
  final int idCajaOpen;
  final int idAperturaCaja;
  final List<int> permisos;

  AuthState({
    this.status = AuthStatus.checking,
    this.token,
    this.userPayload,
    this.isCajaOpen = false,
    this.idCajaOpen = 0,
    this.idAperturaCaja = 0,
    this.permisos = const [],
  });

  bool existePermission(int permiso) {
    return permisos.contains(permiso);
  }

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    TokenPayload? userPayload,
    bool? isCajaOpen,
    int? idCajaOpen,
    int? idAperturaCaja,
    List<int>? permisos,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      userPayload: userPayload ?? this.userPayload,
      isCajaOpen: isCajaOpen ?? this.isCajaOpen,
      idCajaOpen: idCajaOpen ?? this.idCajaOpen,
      idAperturaCaja: idAperturaCaja ?? this.idAperturaCaja,
      permisos: permisos ?? this.permisos,
    );
  }
}