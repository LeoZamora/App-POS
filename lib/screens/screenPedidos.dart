import 'dart:async';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/helpers/formatters.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';
import '../routesApp/appRouter.dart';


class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen>  with RouteAware {
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  final DateTime hoy = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  List<ClienteModel> _clientes = [];
  List<Map<String, dynamic>> detallePedido = [];
  ClienteModel? _clienteSeleccionado;
  int idAperturaCaja = 0;
  String cliente = '';
  String? tipo;
  bool isLoading = false;
  bool isStock = false;

  late Map<String, dynamic> venta = {};
  late List<Map<String, dynamic>> productos = [];
  late List<Map<String, dynamic>> productosConnected = [];
  List<PedidoDetalleModel> pedidoDetalles = [];

  GenericModelCombobox? _estadoSeleccionado;

  // Lista estática basada en tus datos
  final List<GenericModelCombobox> _estadosPedido = [
    GenericModelCombobox(id: 5, nombre: "EP1 - Pendiente"),
    GenericModelCombobox(id: 6, nombre: "EP2 - Programado"),
    GenericModelCombobox(id: 7, nombre: "EP3 - Asignado"),
    GenericModelCombobox(id: 8, nombre: "EP4 - Entregado"),
    GenericModelCombobox(id: 9, nombre: "EP5 - Entrega Parcial"),
  ];

  final TextEditingController fechaDesdeController = TextEditingController();
  final TextEditingController fechaHastaController = TextEditingController();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController noPedidoController = TextEditingController();

  Future<void> loadClientes() async {
    try {
      final response = await getClientes();
      setState(() {
        _clientes = response;
      });
    } catch(e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Fallo al cargar los clientes'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await InternetConnectionChecker.instance.hasConnection;
    if (mounted && hasConnection) {
      setState(() => isConnected = hasConnection);
    }
  }

  Future<void> _getPedidos() async {

    try {
      setState(() => isLoading = true);

      final response = await getPedidoByDetails({
        "idAperturaCaja": idAperturaCaja,
        'desde': fechaDesdeController.text.isEmpty ? formatter.format(hoy) : fechaDesdeController.text,
        'hasta': fechaHastaController.text.isEmpty ? formatter.format(hoy) : fechaHastaController.text,
        'idCliente': _clienteSeleccionado?.idCliente ?? null,
        'idEstadoActual': _estadoSeleccionado?.id ?? null,
        'noPedido': noPedidoController.text.isEmpty ? null : noPedidoController.text,
      });

      setState(() => isLoading = false);


      setState(() {
        pedidoDetalles = response;
      });
    } catch(e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      ToastSnackBar.show(
        context,
        message: 'Fallo al cargar los pedidos ${e.toString()}',
      );
    }
  }

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  final ScrollController _scrollController = ScrollController();
  bool _showShadowBottom = true;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routerObserver.subscribe(this, ModalRoute.of(context)! as ModalRoute<void>);
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        if(_showShadowBottom) {
          setState(() => _showShadowBottom = false);
        }
      } else {
        if(!_showShadowBottom) {
          setState(() => _showShadowBottom = true);
        }
      }
    });

    _checkInitialConnection();

    _connectionStatus = InternetConnectionChecker.instance.onStatusChange.listen((status) async {
      if(mounted) {
        bool newStatus = status == InternetConnectionStatus.connected;

        if(newStatus != isConnected) {
          setState(() => isConnected = newStatus);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(mounted) {
        ref.read(printerProvider).requestBluetoothPermissions(context: context);
        idAperturaCaja = ref.read(authProvider).idAperturaCaja;

        LoadingOverlay.show(context, message: 'Cargando...');
        await Future.wait([
          loadClientes(),
          _getPedidos()
        ]);
        LoadingOverlay.hide();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectionStatus.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    LoadingOverlay.show(context, message: 'Cargando...');
    _getPedidos();
    LoadingOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Pedidos';
    final printerService = ref.watch(printerProvider);

    final estiloInput = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
      labelStyle: const TextStyle(color: Colors.indigo),
    );

    return Scaffold(
      // backgroundColor: Colors.white,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        toolbarHeight: 80,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 0;
        },
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        shadowColor: Colors.grey[200],
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 18.0,
                  letterSpacing: 0.5,
                )
            ),
            Text(
                formatter.format(hoy),
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                    letterSpacing: 0.5
                )
            ),
          ],
        ),
        actions: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: noPedidoController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: 'NO. Pedido',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
                          isDense: true,
                          hintText: 'PE-XX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          )
                      ),
                      style: TextStyle(
                          color: Colors.grey[600],
                          height: 2.5
                      ),
                      cursorHeight: 25,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un número de pedido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownFlutter<ClienteModel>.search(
                      key: const ValueKey('clientes_combobox'),
                      enabled: true,
                      initialItem: _clienteSeleccionado,
                      hintText: 'Seleccione un cliente',
                      items: _clientes,
                      excludeSelected: true,
                      decoration: const CustomDropdownDecoration(
                        expandedFillColor: Colors.white,
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        headerStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        prefixIcon: Icon(Icons.people_outline_rounded, color: Colors.grey),

                        // Bordes
                        closedBorder: Border(
                          top: BorderSide(color: Colors.grey),
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                          right: BorderSide(color: Colors.grey),
                        ),

                        closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                        expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.indigo),
                      ),
                      listItemBuilder: (context, item, isSelected, onItemSelected) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nombre ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              'De: ${item.municipio ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            )
                          ],
                        );
                      },
                      validateOnChange: true,
                      validator: (value) => value == null ? 'Seleccione un cliente' : null,
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          _clienteSeleccionado?.nombre ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        );
                      },
                      onChanged: (val) async {
                        if (val == null) return;

                        setState(() {
                          _clienteSeleccionado = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownFlutter<GenericModelCombobox>.search(
                      enabled: true,
                      // Le damos un key estático ya que la lista no cambia de tamaño
                      key: const ValueKey('estado_pedido_dropdown'),
                      initialItem: _estadoSeleccionado,
                      hintText: 'Seleccione un estado',
                      decoration: const CustomDropdownDecoration(
                        expandedFillColor: Colors.white,
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        headerStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        prefixIcon: Icon(Icons.list_alt_rounded, color: Colors.grey),

                        // Bordes
                        closedBorder: Border(
                          top: BorderSide(color: Colors.grey),
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                          right: BorderSide(color: Colors.grey),
                        ),

                        closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                        expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.indigo),
                      ),
                      items: _estadosPedido, // Pasamos la lista estática aquí
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.nombre ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        );
                      },
                      listItemBuilder: (context, item, isSelected, onItemSelected) {
                        return Text(item.nombre ?? '');
                      },
                      validateOnChange: true,
                      validator: (value) => value == null ? 'Seleccione un estado' : null,
                      onChanged: (value) {
                        if (value != null) {
                          // Como es setState dentro de un State normal o setDialogState si estás en un dialog
                          setState(() {
                            _estadoSeleccionado = value;
                          });

                          // Aquí puedes imprimir o usar value.id (ej. 5) para mandarlo a tu API
                          // print('Estado seleccionado ID: ${value.id}');
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    Row(
                        children: [
                          // 1. Envolvemos el primer campo en Expanded
                          Expanded(
                            child: TextFormField(
                              controller: fechaDesdeController,
                              readOnly: true,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                  labelText: 'Desde',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
                                  isDense: true,
                                  hintText: 'DD/MM/AAAA',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  )
                              ),
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  height: 2.5
                              ),
                              cursorHeight: 25,
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());

                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2050),
                                );
                                if (selectedDate != null) {
                                  String formattedDate =
                                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                  print(formattedDate);
                                  fechaDesdeController.text = formattedDate;
                                }
                              },
                            ),
                          ),

                          // 2. Cambiamos height por width para separar los campos horizontalmente
                          const SizedBox(width: 12),

                          // 3. Envolvemos el segundo campo en Expanded
                          Expanded(
                            child: TextFormField(
                              controller: fechaHastaController,
                              readOnly: true,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                  labelText: 'Hasta',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
                                  isDense: true,
                                  hintText: 'DD/MM/AAAA',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  )
                              ),
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  height: 2.5
                              ),
                              cursorHeight: 25,
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());

                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2050),
                                );
                                if (selectedDate != null) {
                                  String formattedDate =
                                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                  fechaHastaController.text = formattedDate;
                                }
                              },
                            ),
                          ),
                        ]
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _getPedidos(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "BUSCAR",
                              style: TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: pedidoDetalles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'NO HAY PEDIDOS CARGADOS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pedidoDetalles.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidoDetalles[index];
                    final fechaPlana = pedido.fechaRegistro?.split('T').first ?? 'N/A';

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
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
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              pedido.noPedido ?? 'Sin número',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: pedido.isSolicitudCredito! ? Colors.orange.shade50 : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                pedido.isSolicitudCredito! ? 'Crédito' : 'Contado',
                                                style: TextStyle(
                                                  color: pedido.isSolicitudCredito! ? Colors.orange.shade800 : Colors.green.shade800,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          formatedDate(pedido.fechaRegistro),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),

                                const Spacer(),

                                IconButton(
                                    onPressed: () {
                                      context.push('/pedido/${pedido.idPedido}');
                                    },
                                    color: Colors.indigo,
                                    icon: Icon(Icons.visibility_outlined)
                                ),

                                // IconButton(
                                //     onPressed: () {},
                                //     color: Colors.grey,
                                //     icon: Icon(Icons.print_outlined)
                                // )
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Cliente',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          )
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pedido.cliente ?? 'Cliente desconocido',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatedDate(pedido.fechaEntregaSolicitada),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            if (pedido.observaciones != null && pedido.observaciones!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded( // Ahora el Expanded sabe exactamente hasta dónde crecer
                                      child: Text(
                                        pedido.observaciones!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL C\$',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'C\$ ${formattedNumber(pedido.totalAfecha ?? 0.00)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.indigo
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}