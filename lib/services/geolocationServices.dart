import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

class UbicationService {
  Timer? _timer;
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;

  void startLocationUpdatesPeriodically() {
    _timer?.cancel();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      isConnected = await connectionChecker.hasConnection;

      if(isConnected) {
        final Position localidad = await getCurrentLocation();
        final String nombreLocalidad = await getLocalidad(localidad);
        // if(localidad != null) {
        //   await insertIntervalLocation(nombreLocalidad);
        // }
      } else {
        print('No hay conexion a internet');
      }
    });
  }

  void detenerActualizacion() {
    _timer?.cancel();
  }
}

// Future<Position> getCurrentLocation() async {
//   final platform = MethodChannel("printer_channel");
//   bool servicesEnable;
//   LocationPermission permission;
//
//   try {
//     String servicesEnableChannel = await platform.invokeMethod("requestLocationServices");
//     print(servicesEnableChannel);
//     servicesEnable = await Geolocator.isLocationServiceEnabled();
//     if (!servicesEnable) {
//       return Future.error('Location services are disabled.');
//     }
//
//     permission = await Geolocator.checkPermission();
//     if(permission == LocationPermission.denied) {
//       return Future.error('Location permissions are denied');
//     }
//
//     if(permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//   } on PlatformException catch (e) {
//     servicesEnable = false;
//   }
//
//   // final state = context.
//   return await Geolocator.getCurrentPosition();
// }

Future<Position> getCurrentLocation() async {
  final platform = MethodChannel("printer_channel");
  bool servicesEnable;
  LocationPermission permission;

  try {
    String servicesEnableChannel = await platform.invokeMethod("requestLocationServices");
    print(servicesEnableChannel);
  } on PlatformException catch (e) {
    // Si esto falla, no es fatal: seguimos y dejamos que Geolocator
    // valide el estado real del servicio de ubicación más abajo.
    print('Error en requestLocationServices: $e');
  }

  servicesEnable = await Geolocator.isLocationServiceEnabled();
  if (!servicesEnable) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Antes solo tronaba si estaba denegado; ahora al menos intentamos
    // pedirlo una vez más explícitamente por si el diálogo nativo no
    // se disparó bien en este dispositivo.
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }

  // ESTA es la parte que antes quedaba fuera de cualquier try/catch y
  // podía colgarse para siempre en dispositivos sin GPS real o con
  // mala señal (típico en tablets WiFi-only).
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // 'best' es más lento y exige más al GPS
        timeLimit: Duration(seconds: 15),
      ),
    );
  } on TimeoutException {
    print('Timeout obteniendo ubicación, probando con la última conocida...');

    final ultimaConocida = await Geolocator.getLastKnownPosition();
    if (ultimaConocida != null) {
      return ultimaConocida;
    }

    return Future.error(
      'No se pudo obtener la ubicación a tiempo. Verifica que el GPS/ubicación '
          'del dispositivo esté en modo "Alta precisión".',
    );
  }
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
