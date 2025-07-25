import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart' as db;
import 'package:inversiones_ar/dbModels/dbModels.dart';

class StateServices extends ChangeNotifier {
  bool _isLoading = false;
  int _ventasSync = 0;
  int _ventasNotSync = 0;
  double _totalVentas = 0;
  Timer? _timer;

  // GETTERS
  bool get isLoading => _isLoading;
  int get ventasSync => _ventasSync;
  int get ventasNotSync => _ventasNotSync;
  double get totalVentas => _totalVentas;

  void login(bool value) {
    _isLoading = value;
    notifyListeners();
  }
 void logout() {
    _isLoading = false;
    notifyListeners();
 }

 void updateInfoVentas() {
    _timer?.cancel();

    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      _ventasSync = 0;
      _ventasNotSync = 0;
      _totalVentas = 0;
      List<VentaModel> _ventas = await db.DbHelper().getVentas();

      for(var venta in _ventas) {
        DateTime fechaVenta = DateTime.parse(venta.fechaRegistro!);
        DateTime ahora = DateTime.now();
        bool esHoy = fechaVenta.year == ahora.year &&
            fechaVenta.month == ahora.month &&
            fechaVenta.day == ahora.day;

        if(venta.sincronizada == true){
          _ventasSync++;
          if(esHoy) {
            _totalVentas += venta.total!;
          }
        } else {
          _ventasNotSync++;
        }
      }
      notifyListeners();
    });
 }
}