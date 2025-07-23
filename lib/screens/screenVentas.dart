import 'package:flutter/material.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/helpers/formatters.dart' as helpers;
import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  late Future<List<VentaModel>> _ventas;
  List<VentaModel> _ventasLocales = [];
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  final DbHelper dbHelper = DbHelper();
  bool isLoading = true;

  Future<void> getVentasLocales() async  {
    try {
      final ventas = await dbHelper.getVentas();

      setState(() {
        _ventasLocales = ventas.map((venta) => VentaModel.fromMap({
          "idVenta": venta.idVenta,
          "noVenta": venta.noVenta,
          "idCliente": venta.idCliente,
          "cliente": venta.cliente,
          "credito": venta.credito,
          "observaciones": venta.observaciones,
          "enviarA": venta.enviarA,
          "ubicacion": venta.ubicacion,
          "sincronizada": venta.sincronizada,
          "fechaRegistro": venta.fechaRegistro,
          "usuarioRegistro": venta.usuarioRegistro,
          "total": venta.total,
          "estado": venta.estado,
        })).toList();
      });

      print('Ventas locales: ${_ventasLocales[1].toString()}');
    } catch (e) {
      print('Error al obtener las ventas locales: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // _ventas = getVentas();
    getVentasLocales();
    connectionChecker.hasConnection.then((value) async {
      if(mounted) {
        setState(() {
          isConnected = value;
        });

        if(isConnected) {
          await getVentasLocales();
        } else {
          await getVentasLocales();
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
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Ventas Registradas', style: TextStyle(fontSize: 16.0)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.print_outlined,
              color: printerService.selectedDeviceAddress != null ? Colors
                  .lightGreenAccent : Colors.white,
            ),
            tooltip: "Seleccionar Impresora",
            onPressed: printerService.isConnecting ? null : () {
              printerService.showDeviceSelectionDialog(context);
            },
          ),
          IconButton(onPressed: () => {}, icon: Icon(Icons.search))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:  _ventasLocales.isEmpty
                ? const Center(child: Text('NO HAY VENTAS REGISTRADAS', style: TextStyle(fontWeight: FontWeight.bold),))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _ventasLocales.length,
              itemBuilder: (context, i) {
                final venta = _ventasLocales[i];

                return Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              'Venta: #${venta.noVenta}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            // IconButton(
                            //     onPressed: () async {
                            //       // Aquí podrías agregar una vista de detalles
                            //     },
                            //     icon: Icon(
                            //       Icons.visibility_outlined,
                            //       color: Colors.amber.withAlpha(250),
                            //     )
                            // )
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: Colors.indigo),
                            const SizedBox(width: 8,),
                            Text('Cliente: ', style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('${venta.cliente ?? venta.cliente}')
                          ],
                        ),
                        const SizedBox(width: 6,),
                        Row(
                          children: [
                            const Icon(Icons.date_range_outlined, color: Colors.indigo),
                            const SizedBox(width: 8,),
                            Text('Fecha: ', style: TextStyle(fontWeight: FontWeight.bold),),
                            Text('${helpers.formatedDate(venta.fechaRegistro)}')
                          ],
                        ),
                        const SizedBox(width: 6,),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.indigo),
                            const SizedBox(width: 8,),
                            Text('Ubicacion: ', style: TextStyle(fontWeight: FontWeight.bold),),
                          ],
                        ),
                        const SizedBox(width: 6,),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${venta.ubicacion}',
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6,),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: Colors.indigo),
                            const SizedBox(width: 8,),
                            Text('Total: C\$${venta.total}',
                              style: TextStyle(fontWeight: FontWeight.bold),)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          venta.observaciones ?? '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}