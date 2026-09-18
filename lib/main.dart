import 'package:flutter/material.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';
import 'package:inversiones_ar/services/geolocationServices.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/services/syncServices.dart';
import 'package:inversiones_ar/routesApp/appRouter.dart';

final syncServices = SyncServices();
final locationServices = UbicationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  locationServices.startLocationUpdatesPeriodically();
  await initializeDateFormatting('es_ES', null);


  runApp(
    const ProviderScope(child: MyApp())
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.read(routesProvider);

    return MaterialApp.router(
      title: 'DevoDigital',
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
    );
  }
}
