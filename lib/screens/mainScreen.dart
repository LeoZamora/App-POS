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
import 'package:intl/intl.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _selectedIndex = 0;
  final states = StateServices();
  FloatingActionButtonLocation _fabLocation = FloatingActionButtonLocation.endDocked;

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
    }
  ];

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  syncData() async {
    try {
      print('Sincronizando datos...');
      states.updateInfoVentas();
      await db.DbHelper().sincronizarProductosDesdeAPI('Herramientas');
      print('Sincronización completada');
    } catch (e) {
      print('Error en syncData: $e');
    }
  }

  void logout() {
    final authServices = context.read<StateServices>();
    authServices.logout();
    context.go('/login');
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await InternetConnectionChecker.instance
        .hasConnection;
    if (mounted && hasConnection) {
      setState(() => isConnected = hasConnection);
      await syncData();
    }
  }

  @override
  void initState() {
    super.initState();

    _checkInitialConnection();

    _connectionStatus =
        InternetConnectionChecker.instance.onStatusChange.listen((
            status) async {
          if (mounted) {
            bool newStatus = status == InternetConnectionStatus.connected;

            if (newStatus != isConnected) {
              setState(() {
                isConnected = newStatus;
              });

              if (newStatus) {
                await syncData();
              }
            }
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StateServices>().updateInfoVentas();
        context.read<PrinterService>().requestBluetoothPermissions(context: context);
        print('Montada');
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
    final states = context.watch<StateServices>();

    void _onSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 26,
                      // child: Icon(Icons.person_outline, size: 30),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 26,
                        child: ClipOval(
                          child: Image(
                            image: AssetImage('assets/imgs/circleLogo.png'),
                            width: 48, // Ajustado para que encaje bien en el avatar
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "POSVentas",
                          style: TextStyle(color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Operador POS",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          builder: (context) =>
                            UserBottomSheet(
                              onPressed: logout,
                            ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('Ventas Sincronizadas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 10),
                        ),
                        Text('${states.ventasSync}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Ventas por Sincronizar:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 10),
                        ),
                        Text('${states.ventasNotSync}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        Text('TOTAL FACTURADO HOY:',
                          style: TextStyle(
                            fontWeight: FontWeight
                                .bold,
                            color: Colors.white,
                            fontSize: 10),
                        ),
                      ]
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        Text('C\$ ${formattedNumber(states.totalVentas)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16
                          ),
                        )
                      ]
                    )
                  ]
                )
              ],
            )
          ),

          Expanded(
            child: Padding(
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
                      if (item.containsKey("widget") &&
                          item["widget"] != null) {
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
                          BoxShadow(color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(2, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: item['color']?.withOpacity(0.1) ??
                                Colors.grey[200],
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
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
        shape: const CircleBorder(),
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
            await db.DbHelper().sincronizarProductosDesdeAPI('Herramientas');
          },
        ),
      ),
    );
  }
}

class DemoBottomAppBar extends StatefulWidget {
  final VoidCallback onPressedLogout;
  final Future<void> Function() syncData;
  final FloatingActionButtonLocation? fabLocation;
  final NotchedShape? shape;
  final bool isConnected;

  const DemoBottomAppBar({
    this.fabLocation,
    this.shape = const CircularNotchedRectangle(),
    this.isConnected = false,
    required this.onPressedLogout,
    required this.syncData,
    Key? key,
  }) : super(key: key);

  // static final List<FloatingActionButtonLocation> centerLocations = <FloatingActionButtonLocation>[
  //   FloatingActionButtonLocation.endDocked,
  //   FloatingActionButtonLocation.endFloat,
  // ];

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
      await widget.syncData();
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
      notchMargin: 6,
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
                    Icons.cloud_sync_outlined,
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
                  tooltip: "Impresoras",
                ),
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
