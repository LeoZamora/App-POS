import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:inversiones_ar/helpers/formatters.dart' as helpers;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:inversiones_ar/helpers/formatters.dart';

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen> {
  late Future<List<VentaModel>> _ventas;
  late List<VentaModel> _ventasLocales = [];
  bool isConnected = false;
  final connectionChecker = InternetConnectionChecker.instance;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;
  bool isSearching = false;

  VentaModel? venta;
  List<Map<String, dynamic>> detalleVenta = [];

  bool isLoading = true;

  Future<void> getVentasRegistradas() async  {
    try {
      LoadingOverlay.show(context, message: 'Cargando ventas...');
      final ventas = await getVentas();
      LoadingOverlay.hide();

      setState(() {
        _ventasLocales = ventas;
      });
    } catch (e) {
      throw Exception('Error al obtener las ventas locales: $e');
    }
  }

  reImprimirFactura(int idVenta, VentaModel ventaCard, WidgetRef ref) async {
    final printerService = ref.read(printerProvider);

    if(printerService.isPrinting || printerService.isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya se está imprimiendo un ticket.'))
      );
      return;
    }

    if(!mounted) return;

    final cliente = await getClienteById(ventaCard.idCliente ?? 0);

    venta = ventaCard;


    // venta['idVenta'] = ventaCard.idVenta;
    // venta['noVenta'] = ventaCard.noVenta;
    // venta['idCliente'] = cliente.idCliente;
    // venta['nombre'] = cliente.nombre;
    // venta['cliente'] = cliente.nombre;
    // venta['enviarA'] = ventaCard.enviarA;
    // venta['fechaRegistro'] = ventaCard.fechaRegistro;
    // venta['credito'] = ventaCard.credito == 1 ? false : true;
    // venta['ubicacion'] = ventaCard.ubicacion;
    // venta['observaciones'] = ventaCard.observaciones;
    // venta['usuarioRegistro'] = ventaCard.usuarioRegistro;

    // final detalle = await dbHelper.getDetalleVentas(idVenta);
    final detalle = await getVentaById(idVenta);

    detalleVenta.clear();

    for (var item in detalle) {
      if (item.idProducto != null) {
        final producto = await getProductoById(item.idProducto as int);
        detalleVenta.add({
          "idProducto": producto.idProducto,
          "nombre": producto.nombre,
          "cantidad": item.cantidad,
          "precioUnitario": item.precioUnitario,
          "observaciones": item.observaciones,
        });
      }
    }

    await printerService.imprimirFactura(
      context: context,
      venta: venta,
      productos: detalleVenta,
      isCopy: true,
      ivaPorcentaje: 15,
      tipoCambio: 36.50,
    );
  }

  @override
  void initState() {
    super.initState();
    // _ventas = getVentas();
    connectionChecker.hasConnection.then((value) async {
      if(mounted) {
        setState(() {
          isConnected = value;
        });

        await getVentasRegistradas();
      }
    });

    _connectionStatus = connectionChecker.onStatusChange.listen((status) async {
      if(mounted) {
        setState(() {
          isConnected = status == InternetConnectionStatus.connected;
        });

      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        ref.read(printerProvider).requestBluetoothPermissions(context: context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerService = ref.watch(printerProvider);
    final DateTime hoy = DateTime.now();
    // final DateFormat format = DateFormat('dd-MMMM-yyyy');
    final DateFormat format = DateFormat.yMMMMd('ES_NI');

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 0;
        },
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        shadowColor: Colors.grey[200],
        centerTitle: true,
        title: isSearching
          ? TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Buscar...',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
            ),
          )
          : Column(
            children: [
              const Text(
                  'Ventas Registradas',
                  style: TextStyle(
                      fontSize: 18.0,
                      letterSpacing: 0.5
                  )
              ),
              Text(
                  format.format(hoy),
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                      letterSpacing: 0.5
                  )
              ),
            ]
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            color: Colors.grey,
            tooltip: isSearching ? "Cerrar búsqueda" : "Buscar venta",
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {}
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.print_outlined,
              color: printerService.selectedDeviceAddress != null
                  ? Colors.indigo
                  : Colors.grey,
            ),
            tooltip: "Seleccionar Impresora",
            onPressed: printerService.isConnecting ? null : () {
              printerService.showDeviceSelectionDialog(context);
            },
          ),

          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _ventasLocales.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'NO HAY VENTAS REGISTRADAS',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
                  color: Colors.indigo,
                  onRefresh: () async {
                    await getVentasRegistradas();
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 500,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _ventasLocales.length,
                    itemBuilder: (context, i) {
                      final venta = _ventasLocales[i];
                      final esCredito = venta.credito == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- ENCABEZADO ---
                            Row(
                              children: [
                                // Icono de documento con fondo suave
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.indigo,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Número de factura y fecha rápida
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Ticket #${venta.noVenta}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Badge de Crédito/Contado tipo "Pill"
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: esCredito ? Colors.orange.shade50 : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              esCredito ? 'Crédito' : 'Contado',
                                              style: TextStyle(
                                                color: esCredito ? Colors.orange.shade800 : Colors.green.shade800,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        helpers.formatedDate(venta.fechaRegistro),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botón de Reimprimir limpio (tipo InkWell redondeado)
                                Material(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => reImprimirFactura(venta.idVenta ?? 0, venta, ref),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.visibility_outlined,
                                              color: Colors.indigo,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => reImprimirFactura(venta.idVenta ?? 0, venta, ref),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.print_outlined,
                                              color: Colors.grey.shade700,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // --- CUERPO PRINCIPAL ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Cliente
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${venta.cliente ?? venta.nombre}',
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Monto Total destacado
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      'C\$ ${formattedNumber(venta.total!)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // --- UBICACIÓN Y OBSERVACIONES (Opcionales con estilo integrados) ---
                            if ((venta.ubicacion != null && venta.ubicacion.toString().trim().isNotEmpty) ||
                                (venta.observaciones != null && venta.observaciones!.trim().isNotEmpty)) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ubicación
                                    if (venta.ubicacion != null && venta.ubicacion.toString().trim().isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${venta.ubicacion}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                    // Separador sutil si existen ambos
                                    if ((venta.ubicacion != null && venta.ubicacion.toString().trim().isNotEmpty) &&
                                        (venta.observaciones != null && venta.observaciones!.trim().isNotEmpty))
                                      const SizedBox(height: 6),

                                    // Observaciones
                                    if (venta.observaciones != null && venta.observaciones!.trim().isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 13,
                                            color: Colors.amber.shade800,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              venta.observaciones!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  )
                ),
          ),
        ],
      ),
    );
  }
}