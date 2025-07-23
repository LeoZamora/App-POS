import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones_ar/routesApp/routesApp.dart';
import 'package:inversiones_ar/services/geolocationServices.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:inversiones_ar/services/stateServices.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';


Future<void> borrarBaseDeDatos() async {
  final dbPath = await getDatabasesPath();
  final path = '$dbPath/inversiones_ar.db';

  final dbFile = File(path);

  if (await dbFile.exists()) {
    await deleteDatabase(path);
    print('✅ Base de datos eliminada correctamente.');
  } else {
    print('ℹ️ No se encontró el archivo de la base de datos.');
  }
}
final locationServices = UbicationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  locationServices.startLocationUpdatesPeriodically();
  final db = DbHelper();

  // await borrarBaseDeDatos();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PrinterService()),
        ChangeNotifierProvider(create: (context) => StateServices())
      ],
      child: MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  final GoRouter _goRouter = router;
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _goRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.white),
    );
  }
}
