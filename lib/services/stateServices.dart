import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateServices extends ChangeNotifier {
  bool _isLoading = false;
  int _ventasSync = 0;
  int _ventasNotSync = 0;
  double _totalVentas = 0;
  String? _token;
  bool _isInitialized = false;
  Timer? _timer;

  // GETTERS
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;

  bool get isLoading => _isLoading;
  int get ventasSync => _ventasSync;
  int get ventasNotSync => _ventasNotSync;
  double get totalVentas => _totalVentas;

  Future<void> verificarTokenPersistente() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token'); // Intentamos leer el token guardado
    _isInitialized = true;
    notifyListeners(); // Notifica a GoRouter que ya sabemos si hay token o no
  }

  Future<bool> login(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      _token = token;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    notifyListeners();
  }
}