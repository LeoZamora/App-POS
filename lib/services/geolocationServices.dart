import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart' as db;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

class UbicationService {
  Timer? _timer;
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;

  void startLocationUpdatesPeriodically() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      isConnected = await connectionChecker.hasConnection;

      if(isConnected) {
        final Position localidad = await getCurrentLocation();
        final String nombreLocalidad = await getLocalidad(localidad);
        if(localidad != null) {
          await insertIntervalLocation(nombreLocalidad);
        }
      } else {
        print('No hay conexion a internet');
      }
    });
  }

  void detenerActualizacion() {
    _timer?.cancel();
  }
}

Future<Position> getCurrentLocation() async {
  final platform = MethodChannel("printer_channel");
  bool servicesEnable;
  LocationPermission permission;

  try {
    String servicesEnableChannel = await platform.invokeMethod("requestLocationServices");
    print(servicesEnableChannel);
    servicesEnable = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnable) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }

    if(permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

  } on PlatformException catch (e) {
    servicesEnable = false;
  }

  // final state = context.
  return await Geolocator.getCurrentPosition();
}

Future<String> getLocalidad(Position position) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if(placemarks.isNotEmpty) {
      print(placemarks.toString());
      String address = '${placemarks[1].thoroughfare ?? 'Calle no disponible'}, '
          '${placemarks[0].subLocality ?? 'Barrio no disponible'}, '
          '${placemarks[0].locality ?? 'Departamento no disponible'}, '
          '${placemarks[0].country ?? 'Pais no disponible'}';
      return address ?? '';
    } else {
      return 'Ubicacion no encontrada';
    }
  } catch (e) {
    return 'Error al obtener la localidad: $e';
  }
}

Future<void> insertIntervalLocation(String localidad) async {

  final dbHelper = db.DbHelper();
  final database = await dbHelper.database;
  final List<Map<String, dynamic>> existente = await database.query('Ubicacion');

  if(existente.isNotEmpty) {
    print('Actualizando Location $localidad');
    await database.update(
      'Ubicacion',
      {'nombre': localidad},
      where: 'idUbicacion = ?',
      whereArgs: [1],
        );
  } else {
    print('Insertando Location $localidad');
    await database.insert('Ubicacion', {
      'nombre': localidad,
      'fechaRegistro': DateTime.now().toString()
    });
  }
}