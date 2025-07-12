import 'package:flutter/material.dart';
import 'package:inversiones_ar/login/loginApp.dart';
import 'package:path/path.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => PrinterService()),
        ],
        child: MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.white),
      home: LoginApp()
    );
  }
}
