import 'package:flutter/material.dart';
import 'package:inversiones_ar/screens/screenRegistroVentas.dart';
import 'package:inversiones_ar/screens/screenVentas.dart';
import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:provider/provider.dart';
import 'package:inversiones_ar/services/stateServices.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart' as db;
import 'package:go_router/go_router.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _selectedIndex = 0;
  FloatingActionButtonLocation _fabLocation = FloatingActionButtonLocation.centerDocked;

  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  List<Map<dynamic, dynamic>> menuCards = [{
    "title": 'Ventas',
    "icon": Icons.shopping_cart_outlined,
    "widget": VentasScreen()
  }, {
    "title": 'Registro de Ventas',
    "icon": Icons.drive_file_rename_outline_outlined,
    "widget": RegistroVentas()
  }];

   syncData () async {
     print('Sincronizando datos...');
     await db.DbHelper().sincronizarProductosDesdeAPI('Herramientas');
     // await db.DbHelper().sincronizarProductosDesdeAPI('Producto Terminado');
  }

  void logout() {
    final authServices = context.read<StateServices>();
    authServices.logout();
    context.go('/login');
  }

  @override
  void initState() {
    super.initState();

    connectionChecker.hasConnection.then((value) async {
      if(mounted) {
        setState(() {
          isConnected = value;
        });

        if(isConnected) {
          await syncData();
        }
      }
    });

    _connectionStatus = connectionChecker.onStatusChange.listen((status) async {
      if(mounted) {
        setState(() {
          isConnected = status == InternetConnectionStatus.connected;
        });

        if(status == InternetConnectionStatus.connected) {
          // await syncData();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        context.read<PrinterService>().requestBluetoothPermissions(context: context);
      }
    });
  }

  @override
  void dispose() {
    _connectionStatus.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();

    void _onSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Inversiones Zafiro'),
        actions: [
          Icon( isConnected ? Icons.wifi : Icons.wifi_off, color: isConnected ? Colors.green : Colors.redAccent),
          Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: menuCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = menuCards[index];
            return GestureDetector(
              onTap: () {
                if (item.containsKey("widget") && item["widget"] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item["widget"]),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: item['color']?.withOpacity(0.1) ?? Colors.grey[200],
                      child: Icon(
                        item['icon'],
                        size: 30,
                        color: item['color'] ?? Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: _fabLocation,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistroVentas()),
          );
        },
        tooltip: 'Registrar Ventas',
        child: const Icon(Icons.add),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        shape: CircleBorder(),
      ),
      bottomNavigationBar: SizedBox(
        height: 60.0,
        width: double.infinity,
        child: DemoBottomAppBar(
          fabLocation: _fabLocation,
          shape: const CircularNotchedRectangle(),
          isConnected: isConnected,
          onPressedLogout: logout,
          syncData: () async {
            print('Sincronizando datos...');
            await db.DbHelper().sincronizarProductosDesdeAPI('Herramientas');
            // await db.DbHelper().sincronizarProductosDesdeAPI('Producto Terminado');
          },
        ),
      ),
    );
  }
}

class DemoBottomAppBar extends StatefulWidget {
  final VoidCallback onPressedLogout;
  final Future<void> Function() syncData;
  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;
  final bool isConnected;

  const DemoBottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
    this.isConnected = false,
    required this.onPressedLogout,
    required this.syncData,
    Key? key,
  }) : super(key: key);

  static final List<FloatingActionButtonLocation> centerLocations = <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];

  @override
  _DemoBottomAppBarState createState() => _DemoBottomAppBarState();
}

class _DemoBottomAppBarState extends State<DemoBottomAppBar> {
  final printerService = PrinterService();
  bool sync = false;

  Future<void> _handleSync() async {
    if (widget.syncData == null) return;
    setState(() {
      sync = true;
    });

    try {
      // await Future.delayed(const Duration(seconds: 3));
      await widget.syncData();
      print('Sincronizando2...');
    } finally {
      if (mounted) {
        setState(() {
          sync = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if(widget.isConnected) {
      _handleSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: widget.shape,
      color: Colors.indigo,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                sync ? Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )  : IconButton(
                  onPressed: _handleSync,
                  icon: Icon(
                    Icons.sync,
                    color: widget.isConnected ? Colors.green : Colors.white,
                  ),
                  tooltip: "Sincronizar Ventas",
                ),
                IconButton(
                  onPressed: printerService.isConnecting ? null : () {
                    printerService.showDeviceSelectionDialog(context);
                  },
                  icon: Icon(
                    Icons.print_outlined,
                    color: printerService.selectedDeviceAddress != null ? Colors.green : Colors.white,
                  ),
                  tooltip: "Sincronizar Ventas",
                ),
              ],
            ),
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                      builder: (context) {
                        return UserBottomSheet(
                          onPressed: widget.onPressedLogout,
                        );
                      }
                    );
                  },
                  icon: Icon(Icons.person_outline, color: Colors.white),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserBottomSheet extends StatelessWidget {
  final VoidCallback onPressed;
  const UserBottomSheet({super.key, required this.onPressed});


  @override
  Widget build(BuildContext context) {
    final String nombreUsuario = 'POSVentas';
    final String rolUsuario = 'Operador POS';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle, size: 48, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            nombreUsuario,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            rolUsuario,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
