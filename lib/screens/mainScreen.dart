import 'package:flutter/material.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/screens/screenPedidos.dart';
import 'package:inversiones_ar/screens/screenRegistroPedido.dart';
import 'package:inversiones_ar/screens/screenRegistroVentas.dart';
import 'package:inversiones_ar/screens/screenVentas.dart';
import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:inversiones_ar/screens/sreenRetiroEfectivo.dart';
import 'package:inversiones_ar/services/stateServices.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones_ar/routesApp/appRouter.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/widgets/alertReusable.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> with RouteAware {
  final states = StateServices();
  final FloatingActionButtonLocation _fabLocation = FloatingActionButtonLocation.endDocked;

  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  bool isLoading = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  AperturaCajaModel? _resumenCaja;
  ResumenTotalesModel? _resumenTotales;

  List<Map<dynamic, dynamic>> menuCards = [
    {
      "title": 'Ventas',
      "icon": Icons.shopping_cart_outlined,
      "widget": VentasScreen(),
      "exclude": false,
      "requiredPer": 32,
    },
    {
      "title": 'Registrar Pedido',
      "icon": Icons.drive_file_rename_outline_outlined,
      "widget": RegistroPedido(),
      "exclude": false,
      "requiredPer": 142
      // "requiredPer": 32,
    },
    {
      "title": 'Entregar Pedido',
      "icon": Icons.receipt_long,
      "exclude": false,
      "widget": PedidosScreen(),
      "requiredPer": 147
      // "requiredPer": 32,
    },
    {
      "title": 'Retirar Efectivo',
      "icon": Icons.receipt_long,
      "exclude": true,
      "widget": EgresosCapitalScreen(),
      "requiredPer": 147
      // "requiredPer": 32,
    }
  ];

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  void _confirmCloseCaja(BuildContext context) async {
    final closeCaja = await AlertReusable.show(
      context,
      title: "Arquear Caja",
      message: '¿Estás seguro de que deseas hacer realizar el arqueo?',
      yesText: 'Si',
      noText: 'NO',
      icon: Icons.calculate_outlined,
      primaryColor: Colors.indigo,
    );

    if(closeCaja) {
      // await ref.read(authProvider.notifier).closeCaja();
      context.push('/caja/true');
    } else {
      context.pop();
    }
  }

  void _confirmCerrarSesion(BuildContext context) async {
    final closeCaja = await AlertReusable.show(
      context,
      title: "Cerrar Sesión",
      message: '¿Estás seguro de que deseas cerrar la sesión?',
      yesText: 'Si',
      noText: 'NO',
      icon: Icons.logout_rounded,
      primaryColor: Colors.red,
    );

    if(closeCaja) {
      LoadingOverlay.show(
        context,
        message: 'Cerrando sesión...',
      );
      await ref.read(authProvider.notifier).logout();
      LoadingOverlay.hide();
    }
  }

  void logout(WidgetRef currentRef) async {
    await currentRef.watch(authProvider.notifier).logout();
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await InternetConnectionChecker.instance
        .hasConnection;
    if (mounted && hasConnection) {
      setState(() => isConnected = hasConnection);
    }
  }


  Future<void> resumenCaja(int idCaja) async {
    try {
      setState(() => isLoading = true);
      final result = await Future.wait([
        getAperturaCaja(idCaja),
        getResumenCajaTotales(idCaja),
        ref.read(authProvider.notifier).checkAuthStatus(),
      ]);

      if (!mounted) return;

      setState(() => isLoading = false);

      final AperturaCajaModel response = result[0] as AperturaCajaModel;
      final ResumenTotalesModel response2 = result[1] as ResumenTotalesModel;

      setState(() {
        _resumenCaja = response;
        _resumenTotales = response2;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() => isLoading = false);
      ToastSnackBar.show(
        context,
        type: ToastType.error,
        message: e.toString(),
      );
    }
  }

  int getCrossAxisCount(double width) {
    if (width >= 1200) {
      return 5;
    } else if (width >= 900) {
      return 4;
    } else if (width >= 600) {
      return 3;
    } else {
      return 2;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routerObserver.subscribe(this, ModalRoute.of(context)! as ModalRoute<void>);
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
            }
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await resumenCaja(ref.read(authProvider).idCajaOpen);
        ref.read(printerProvider).requestBluetoothPermissions(context: context);
      }
    });
  }

  @override
  void dispose() {
    _connectionStatus.cancel();
    routerObserver.unsubscribe(this);
    super.dispose();
  }

  void didPopNext() {
    final int idCaja = ref.read(authProvider).idCajaOpen;
    resumenCaja(idCaja);
  }

  @override
  Widget build(BuildContext context) {
    final TokenPayload? userPayload = ref.watch(authProvider).userPayload;
    final authState = ref.watch(authProvider);

    final cardsPermitidas = menuCards.where((item) {
      final int codigoPermiso = item['requiredPer'];

      return authState.existePermission(codigoPermiso) || item['exclude'] == true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        toolbarHeight: 80,
        titleSpacing: 16,
        title: Container(
          padding: const EdgeInsets.fromLTRB(0, 48, 0, 30),
          child: Column(
            children: [
              Row(
                children: [
                  Image(
                    image: const AssetImage('assets/devo/32px.png'),
                    width: 150,
                    height: 50,
                    fit: BoxFit.fitHeight,
                  ),

                  const Spacer(),

                  IconButton(
                    // backgroundRadius: 20,
                    icon: const Icon(Icons.account_circle_outlined, color: Colors.indigo, size: 30),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => UserBottomSheet(onPressed: _confirmCerrarSesion),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    children: [
                      if(authState.existePermission(32))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xff1a237e),
                              backgroundBlendMode: BlendMode.darken,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Resumen de ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              (_resumenCaja?.cajaNombre ?? 'Totales').toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                  ],
                                ),

                                const SizedBox(height: 5),
                                const Divider(height: 1, color: Colors.white30),
                                const SizedBox(height: 5),

                                // --- DESGLOSE DE VENTAS ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total de Pedidos:',
                                      style: TextStyle(color: Colors.white70, fontSize: 15),
                                    ),

                                    !isLoading ? Text(
                                      'C\$ ${formattedNumber((_resumenTotales?.totalPedidos ?? 0).toDouble())}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    ) : LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 20
                                    ),
                                  ],
                                ),

                                if (authState.existePermission(32)) const SizedBox(height: 5),

                                // if (authState.existePermission(32)) Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     const Text(
                                //       'Valor Mercaderia:',
                                //       style: TextStyle(color: Colors.white70, fontSize: 15),
                                //     ),
                                //
                                //     !isLoading ? Text(
                                //       'C\$ ${formattedNumber((_resumenTotales?.totalMercaderia ?? 0).toDouble())}',
                                //       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                //     ) : LoadingAnimationWidget.waveDots(
                                //         color: Colors.white,
                                //         size: 20
                                //     ),
                                //   ],
                                // ),

                                if (authState.existePermission(32)) const SizedBox(height: 5),

                                if (authState.existePermission(32)) Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Egresos:',
                                      style: TextStyle(color: Colors.white70, fontSize: 15),
                                    ),
                                    !isLoading ? Text(
                                      'C\$ ${formattedNumber((_resumenTotales?.totalRetiros ?? 0).toDouble())}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    ) : LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 20
                                    ),
                                  ],
                                ),

                                if (authState.existePermission(32)) const SizedBox(height: 5),

                                if (authState.existePermission(32)) Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Apertura con:',
                                      style: TextStyle(color: Colors.white70, fontSize: 15),
                                    ),
                                    !isLoading ? Text(
                                      'C\$ ${formattedNumber((_resumenTotales?.efectivoApertura ?? 0).toDouble())}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    ) : LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 20
                                    ),
                                  ],
                                ),

                                if (authState.existePermission(32)) const SizedBox(height: 5),

                                if (authState.existePermission(32)) Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total de Ventas:',
                                      style: TextStyle(color: Colors.white70, fontSize: 15),
                                    ),
                                    !isLoading ? Text(
                                      'C\$ ${formattedNumber((_resumenTotales?.totalVentas ?? 0).toDouble())}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    ) : LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 20
                                    ),
                                  ],
                                ),


                                const SizedBox(height: 5),
                                const Divider(height: 1, color: Colors.white30),
                                const SizedBox(height: 5),

                                // --- DESGLOSE DE VENTAS ---

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Icon(Icons.currency_exchange_outlined, color: Colors.white, size: 30),
                                    Column(
                                      // mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        !isLoading ? Text(
                                          'C\$ ${formattedNumber((_resumenTotales?.totalEnCaja ?? 0).toDouble())}',
                                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500),
                                        ) : LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 50
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                          child: GridView.builder(
                              shrinkWrap: true,
                              itemCount: cardsPermitidas.length,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 250,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.1,
                              ),
                              itemBuilder: (context, index) {
                                final item = cardsPermitidas[index];
                                final Color cardColor = item['color'] ?? Colors.indigo;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    // Borde más sutil
                                    border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04), // Sombra mucho más suave
                                        blurRadius: 15, // Más difuminada
                                        offset: const Offset(0, 8), // Un poco más abajo para dar profundidad
                                      )
                                    ],
                                  ),
                                  // Material va DENTRO del Container y es transparente para mostrar el fondo
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    clipBehavior: Clip.antiAlias, // Evita que el toque se salga de los bordes curvos
                                    child: InkWell(
                                      splashColor: Colors.indigo[100], // El toque toma el color de tu tema
                                      highlightColor: Colors.indigo[100],
                                      onTap: () {
                                        if (item.containsKey("widget") && item["widget"] != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => item["widget"]),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0), // Mejor balance de espacios
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Contenedor del Icono
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: cardColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                item['icon'],
                                                size: 30,
                                                color: cardColor,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              item['title'],
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2D3748),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                          )
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                )
              )
            ),
          ),
        ],
      ),

      // --- BOTÓN FLOTANTE (FAB) INTEGRADO PERFECTAMENTE EN EL NOTCH ---
      floatingActionButtonLocation: authState.existePermission(32) ? FloatingActionButtonLocation.endDocked : null,
      floatingActionButton: authState.existePermission(32) ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistroVentas()),
          );
        },
        tooltip: 'Registrar Ventas',
        backgroundColor: const Color(0xffe65100),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ) : null,

      bottomNavigationBar: DemoBottomAppBar(
        onPressed: _confirmCloseCaja,
        fabLocation: _fabLocation,
        shape: const CircularNotchedRectangle(),
        isConnected: isConnected,
        onPressedLogout: () {
          logout(ref);
        },
      ),
    );
  }
}

class DemoBottomAppBar extends ConsumerStatefulWidget {
  final FloatingActionButtonLocation fabLocation;
  final NotchedShape shape;
  final bool isConnected;
  final VoidCallback onPressedLogout;
  final void Function(BuildContext) onPressed;

  const DemoBottomAppBar({
    super.key,
    required this.fabLocation,
    required this.shape,
    required this.isConnected,
    required this.onPressedLogout,
    required this.onPressed,
  });

  @override
  ConsumerState<DemoBottomAppBar> createState() => _DemoBottomAppBarState();
}

class _DemoBottomAppBarState extends ConsumerState<DemoBottomAppBar> {
  final printerService = PrinterService();
  bool sync = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: widget.shape,
      color: Colors.white,
      notchMargin: 8,
      elevation: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          IconButton(
            onPressed: printerService.isConnecting
                ? null
                : () => printerService.showDeviceSelectionDialog(context),
            icon: Icon(
              Icons.print_outlined,
              color: printerService.selectedDeviceAddress != null ? Colors.indigo : Colors.grey[600],
            ),
            tooltip: "Impresoras",
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => widget.onPressed(context),
            icon: Icon(
              Icons.point_of_sale_rounded,
              color: printerService.selectedDeviceAddress != null ? Colors.indigo : Colors.grey[600],
            ),
            tooltip: "Arquear Caja",
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTE: MENU DESPLEGABLE DE USUARIO ---
class UserBottomSheet extends ConsumerWidget {
  final void Function(BuildContext) onPressed;

  const UserBottomSheet({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String nombreUsuario = ref.watch(authProvider).userPayload?.usuario ?? 'Usuario Desconocido';
    String rolUsuario = ref.watch(authProvider).userPayload?.rol ?? 'Rol Desconocido';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Línea superior decorativa del bottom sheet
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 40, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            Text(
              nombreUsuario,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              rolUsuario,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),

            const Divider(height: 32, color: Colors.grey, thickness: .5),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onPressed(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}