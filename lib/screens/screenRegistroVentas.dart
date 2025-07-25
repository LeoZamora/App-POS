import 'package:flutter/material.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart' as db;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:inversiones_ar/services/geolocationServices.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RegistroVentas extends StatefulWidget {
  const RegistroVentas({super.key});

  @override
  State<RegistroVentas> createState() => _RegistroVentasState();
}

class _RegistroVentasState extends State<RegistroVentas> {
  final _formKey = GlobalKey<FormState>();
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  List<ProductoModel> _productos = [];
  List<TipoProductoModel> _tiposProductos = [];
  List<ProductoModel> _productosLocales = [];
  List<ClienteModel> _clientesLocales = [];
  List<Map<String, dynamic>> detalleVenta = [];
  ClienteModel? _clienteSeleccionado;
  bool _esCredito = false;
  String cliente = '';
  String? tipo;
  String? _selectedProductId;
  bool isStock = false;

  late Future<List<ClienteModel>> _clientes;
  late Future<List<ClienteModel>> _clientesLocalFuture;
  late Map<String, dynamic> venta = {};
  late List<Map<String, dynamic>> productos = [];
  late List<Map<String, dynamic>> productosConnected = [];
  double totalVenta = 0.0;

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController enviarAController = TextEditingController();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController noVentaController = TextEditingController();
  final Map<int, TextEditingController> _precioControllers = {};

  Future<void> loadProductos(String tipo) async {
    try {
      setState(() {
        _productos = [];
      });
      final productos = await getProductos(tipo);

      setState(() {
        _productos = productos;
      });
    } catch (e) {
      print("Error cargando productos: $e");
    }
  }

  Future<void> getTipoProductos() async {
    final dbHelper = db.DbHelper();
    final productos = await dbHelper.getTipoProducto();

    setState(() {
      _tiposProductos = productos.map((prod) => TipoProductoModel.fromMap({
        "idTipoProducto": prod.idTipoProducto,
        "nombre": prod.nombre,
      })).toList();
    });
  }

  bool verifyData() {
    if(noVentaController.text.isEmpty ||
        clienteController.text.isEmpty ||
        enviarAController.text.isEmpty ||
        observacionesController.text.isEmpty ||
        detalleVenta.isEmpty
    ) {
      return false;
    }
    return true;
  }

  Future<void> getProductosLocal(String tipoProducto) async {
    final dbHelper = db.DbHelper();
    try {
      setState(() {
        _productosLocales = [];
      });
      final productosLocal = await dbHelper.getProductos(tipoProducto);

      setState(() {
        _productosLocales = productosLocal.map((prod) => ProductoModel.fromMap({
          'idProducto': prod.idProducto,
          'nombre': prod.nombre,
          'tipoProducto': prod.tipoProducto,
          'precio': prod.precio,
          'estado': prod.estado,
          'imagen': prod.imagen,
          'observaciones': prod.observaciones,
          'cantidadMinima': prod.cantidadMinima,
          'cantidadTotal': prod.cantidadTotal,
          'costo': prod.costo,
          'idSubCatProd': prod.idSubCatProd,
          'idUnidadMedida': prod.idUnidadMedida,
          'codigo': prod.codigo,
          'fechaRegistro': prod.fechaRegistro,
          'usuarioRegistro': prod.usuarioRegistro,

        })).toList();
        print('Hola');
      });
    } catch (e) {
      print("Error cargando productos: $e");
    }

  }

  Future<List<ClienteModel>> getClientesLocales() async {
    final dbHelper = db.DbHelper();
    try {
      final clientes = await dbHelper.getClientesLocal();

      setState(() {
        _clientesLocales = clientes.map((cliente) => ClienteModel.fromMap({
          "idCliente": cliente.idCliente,
          "codigo": cliente.codigo,
          "direccion": cliente.direccion,
          "telefono": cliente.telefono,
          "departamento": cliente.departamento,
          "municipio": cliente.municipio,
          "personaNatural": cliente.personaNatural,
          "fechaRegistro": cliente.fechaRegistro,
          "usuarioRegistro": cliente.usuarioRegistro,
          "estado": cliente.estado,
        })).toList();
      });

      return _clientesLocales;
    } catch (e) {
      print('Error al cargar clientes: $e');
      return _clientesLocales;
    }
  }

  Future<void> _imprimirFactura() async {
    final printerService = context.read<PrinterService>();
    late String location;
    if(printerService.isPrinting || printerService.isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya se está imprimiendo una factura.'))
      );
      return;
    }

    if(!mounted) return;

    if(isConnected) {
      print('CONECTADO');
      Position position = await getCurrentLocation();
      String localidad = await getLocalidad(position);
      setState(() {
        location = localidad;
        productosConnected.clear();

        for (var item in detalleVenta) {
          if (item['idProducto'] != null && item['nombre'] != null) {
            productosConnected.add({
              "idVenta": 0,
              "idProducto": item['idProducto'],
              "cantidad": item['cantidad'],
              "precioUnitario": item['precioUnitario'],
              "observaciones": "Sin detalles"
            });
          }
        }

        productos.clear();

        for (var item in detalleVenta) {
          if (item['idProducto'] != null && item['nombre'] != null) {
            productos.add({
              "nombre": item['nombre'],
              "cantidad": item['cantidad'],
              "precioUnitario": item['precioUnitario'],
            });
          }
        }
      });

      venta = {
        "noVenta": noVentaController.text,
        "idCliente": _clienteSeleccionado?.codigo,
        // "idCliente": clienteController.text,
        "enviarA": enviarAController.text,
        "fechaRegistro": new DateTime.now().toString(),
        "ubicacion": location,
        "observaciones": observacionesController.text,
        "credito": _esCredito,
        "usuarioRegistro": productosConnected
      };

      final result = await postVentas({
        "noVenta": noVentaController.text.toString(),
        "idCliente": _clienteSeleccionado?.idCliente,
        "credito": _esCredito,
        "observaciones": observacionesController.text,
        "ubicacion": location,
        "enviarA": enviarAController.text,
        "usuarioRegistro": 'POSVentas',
        "detalleVenta": productosConnected
      });

      if(result?['code'] != 400 || result?['code'] != 404 ) {
        final nuevaVenta = VentaModel(
            noVenta: noVentaController.text,
            idCliente: _clienteSeleccionado?.idCliente ?? 0,
            credito: _esCredito,
            cliente: _clienteSeleccionado?.codigo ?? '',
            ubicacion: location,
            sincronizada: true,
            observaciones: observacionesController.text,
            enviarA: enviarAController.text,
            fechaRegistro: new DateTime.now().toString(),
            usuarioRegistro: 'POSVentas',
            total: totalVenta
        );

        final List<DetalleVentaModel> detalle = detalleVenta.map((map) {
          return DetalleVentaModel(
            idProducto: map['idProducto'] is int
                ? map['idProducto']
                : int.parse(map['idProducto'].toString()),
            cantidad: map['cantidad'] is double
                ? map['cantidad']
                : double.parse(map['cantidad'].toString()),
            precioUnitario: map['precioUnitario'] is double
                ? map['precioUnitario']
                : double.parse(map['precioUnitario'].toString()),
            observaciones: "Sin detalles",
          );
        }).toList();

        await db.DbHelper().registrarVenta(nuevaVenta,  detalle);
        final bool success = await printerService.imprimirFactura(
          context: context,
          venta: venta,
          productos: productos,
          ivaPorcentaje: 15,
          tipoCambio: 36.6243,
        );

        if(success) {
          final num = await _getNumeroVenta();
          await db.DbHelper().insertNoVenta(num);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venta registrada'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo registrar la venta.'))
        );
        return;
      }
    } else {
      print('DESCONECTADO');
      final Map<String, dynamic> ubicacion = await db.DbHelper().getUbicacion();
      setState(() {
        productos.clear();
        location = ubicacion['nombre'] ?? 'No disponible';

        for (var item in detalleVenta) {
          if (item['idProducto'] != null && item['nombre'] != null) {
            productos.add({
              "nombre": item['nombre'],
              "cantidad": item['cantidad'],
              "precioUnitario": item['precioUnitario'],
            });
          }
        }
      });

      venta = {
        "noVenta": noVentaController.text,
        "idCliente": _clienteSeleccionado?.codigo,
        "enviarA": enviarAController.text,
        "fechaRegistro": new DateTime.now().toString(),
        "observaciones": observacionesController.text,
        "credito": _esCredito,
        "usuarioRegistro": productosConnected
      };

      if(productos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrese uno o mas productos a facturar.'))
        );
        return;
      } else {

        final nuevaVenta = VentaModel(
          noVenta: noVentaController.text,
          idCliente: _clienteSeleccionado?.idCliente ?? 0,
          credito: _esCredito,
          cliente: _clienteSeleccionado?.codigo ?? '',
          sincronizada: false,
          ubicacion: location,
          observaciones: observacionesController.text,
          enviarA: enviarAController.text,
          fechaRegistro: new DateTime.now().toString(),
          usuarioRegistro: 'POSVentas',
          total: totalVenta
        );

        final List<DetalleVentaModel> detalle = detalleVenta.map((map) {
          print(map.toString());
          return DetalleVentaModel(
            idProducto: map['idProducto'] is int
                ? map['idProducto']
                : int.parse(map['idProducto'].toString()),
            cantidad: map['cantidad'] is double
                ? map['cantidad']
                : double.parse(map['cantidad'].toString()),
            precioUnitario: map['precioUnitario'] is double
                ? map['precioUnitario']
                : double.parse(map['precioUnitario'].toString()),
            observaciones: "Sin detalles",
          );
        }).toList();

        await db.DbHelper().registrarVenta(nuevaVenta,  detalle);
        final bool success = await printerService.imprimirFactura(
          context: context,
          venta: venta,
          productos: productos,
          ivaPorcentaje: 15,
          tipoCambio: 36.6243,
        );
        if(success) {
          final num = await _getNumeroVenta();
          await db.DbHelper().insertNoVenta(num);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Factura enviada'))
          );
        }
      }
    }
  }

  void actualizarTotal() {
    double total = 0.0;
    for (var item in detalleVenta) {
      final cantidad = double.tryParse(item['cantidad'].toString()) ?? 0;
      final precio = double.tryParse(item['precioUnitario'].toString()) ?? 0;
      total += cantidad * precio;
    }

    setState(() {
      totalVenta = total;
    });
  }

  void agregarProducto() {
    setState(() {
      detalleVenta.add({
        'tipoProducto': '',
        'idProducto': 0,
        'nombre': '',
        'precioUnitario': 0.0,
        'cantidad': 1,
        'total': 0.0,
        'productosFiltrados': [],
      });
    });
    actualizarTotal();
  }

  void eliminarProducto(int index) {
    setState(() {
      detalleVenta.removeAt(index);
    });
    actualizarTotal();
  }

  void calcularTotalItem(int index) {
    final cantidad = double.tryParse(detalleVenta[index]['cantidad'].toString()) ?? 0;
    final precio = double.tryParse(detalleVenta[index]['precioUnitario'].toString()) ?? 0;
    final total = cantidad * precio;
    setState(() {
      detalleVenta[index]['total'] = total;
    });
    actualizarTotal();
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await InternetConnectionChecker.instance.hasConnection;
    if (mounted && hasConnection) {
      setState(() => isConnected = hasConnection);
    }
  }

  void _mostrarDialogoMontos() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ShowDialogMontos(
          montoTotal: totalVenta,
          impimir: _imprimirFactura,
        ),
      ),
    );
  }

  Future<void> _setNumeroVenta() async {
    final numero = await _getNumeroVenta();
    noVentaController.text = 'POS-$numero';
  }

  Future<int> _getNumeroVenta() {
    final dbHelper = db.DbHelper();
    return dbHelper.getNumeroSugerido();
  }

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  @override
  void initState() {
    super.initState();
     _clientes = getClientes();
     _clientesLocalFuture = getClientesLocales();
     getTipoProductos();
     getClientesLocales();
     _setNumeroVenta();

     _checkInitialConnection();

     _connectionStatus = InternetConnectionChecker.instance.onStatusChange.listen((status) async {
       if(mounted) {
         bool newStatus = status == InternetConnectionStatus.connected;

         if(newStatus != isConnected) {
           setState(() => isConnected = newStatus);
           print('SINCROIZANDO .....');
           await getProductosLocal('Herramientas');
           await getTipoProductos();
           await getClientesLocales();
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
      appBar: AppBar(
        title: const Text('Registrar Venta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(inputDecorationTheme: estiloInput),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: noVentaController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'No. Venta',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<ClienteModel>>(
                      future: _clientesLocalFuture,
                      builder: (context, snapshot) {
                        final clientes = snapshot.data ?? [];

                        return DropdownButtonFormField<ClienteModel>(
                          value: _clienteSeleccionado,
                          isDense: true,
                          hint: const Text('Seleccione un cliente'),
                          onChanged: (value) => setState(() => _clienteSeleccionado = value),
                          items: clientes.map((cliente) {
                            return DropdownMenuItem<ClienteModel>(
                              value: cliente,
                              child: Text(cliente.codigo ?? 'Sin nombre'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        _esCredito ? 'Venta a crédito' : 'Contado',
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                      activeColor: Colors.indigo,
                      value: _esCredito,
                      onChanged: (v) => setState(() => _esCredito = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: enviarAController,
                      decoration: const InputDecoration(
                        labelText: 'Enviar a',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[300]),
                    const Text(
                      "Detalle de productos",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...detalleVenta.asMap().entries.map((entry) {
                      final index = entry.key;
                      final producto = entry.value;
                      final productos = isConnected ? _productos : _productosLocales;
                      final uniqueTiposProductos = _tiposProductos.toSet().toList();

                      if (!_precioControllers.containsKey(index)) {
                        _precioControllers[index] = TextEditingController(
                          text: producto['precioUnitario'].toString(),
                        );
                      } else {
                        _precioControllers[index]!.text = producto['precioUnitario'].toString();
                      }

                      return Card(
                        elevation: 2.5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Selecciona un tipo de producto'),
                                isDense: true,
                                isExpanded: true,
                                value: tipo,
                                hint: const Text("Tipo de producto"),
                                onChanged: (String? value) async {
                                  setState(() {
                                    producto['tipoProducto'] = value!;
                                    producto['idProducto'] = 0;
                                    producto['nombre'] = '';
                                    producto['precioUnitario'] = 0.0;
                                    producto['total'] = 0.0;
                                    producto['productosFiltrados'] = [];
                                  });

                                  final productosFiltrados = isConnected
                                      ? await getProductos(value.toString())
                                      : await db.DbHelper().getProductos(value.toString());

                                  setState(() {
                                    producto['productosFiltrados'] = productosFiltrados;
                                  });
                                },
                                validator: (value) => value == null ? 'Seleccione un tipo de producto' : null,
                                items: uniqueTiposProductos.map((tipo) {
                                  return DropdownMenuItem<String>(
                                    value: tipo.nombre,
                                    child: Text(tipo.nombre.toString()),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: producto['idProducto'] == 0 ? null : producto['idProducto'].toString(),
                                hint: const Text("Producto"),
                                isExpanded: true,
                                onChanged: (value) {
                                  setState(() {
                                    isStock = false;
                                    final selected = producto['productosFiltrados'].firstWhere(
                                          (p) => p.idProducto.toString() == value.toString(),
                                    );
                                    if (selected.cantidadTotal <= 0 || selected.cantidadTotal == null) {
                                      isStock = true;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No hay stock disponible')),
                                      );
                                      detalleVenta.removeAt(index);
                                      return;
                                    }
                                    producto['idProducto'] = selected.idProducto;
                                    producto['nombre'] = selected.nombre;
                                    producto['precioUnitario'] = selected.precio;
                                    producto['total'] = 0;
                                    calcularTotalItem(index);
                                  });
                                },
                                items: (producto['productosFiltrados'] as List)
                                    .map<DropdownMenuItem<String>>((prod) {
                                  return DropdownMenuItem<String>(
                                    value: prod.idProducto.toString(),
                                    child: Text(prod.nombre),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: producto['cantidad'].toString(),
                                      keyboardType: TextInputType.number,
                                      readOnly: isStock,
                                      decoration: const InputDecoration(labelText: 'Cantidad'),
                                      onChanged: (value) {
                                        setState(() {
                                          producto['cantidad'] = double.tryParse(value) ?? 1;
                                          producto['total'] = producto['precioUnitario'] * producto['cantidad'];
                                          calcularTotalItem(index);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precioControllers[index],
                                      keyboardType: TextInputType.number,
                                      readOnly: isStock,
                                      decoration: const InputDecoration(labelText: 'Precio U'),
                                      onChanged: (value) {
                                        final precio = double.tryParse(value);
                                        if (precio != null) {
                                          setState(() {
                                            producto['precioUnitario'] = precio;
                                            calcularTotalItem(index);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: detalleVenta[index]['total'].toStringAsFixed(2),
                                      ),
                                      decoration: const InputDecoration(labelText: 'Total'),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => eliminarProducto(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: agregarProducto,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Agregar producto"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.indigo),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text("Registrar Venta", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if(_clienteSeleccionado == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Seleccione un cliente')),
                            );
                            return;
                          }

                          if(detalleVenta.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingrese uno o mas productos a facturar.'))
                            );
                            return;
                          }

                          for(var item in detalleVenta) {
                            if(item['precioUnitario'] == null || item['precioUnitario'] <= 0 ) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('El producto ${item['nombre']} no tiene precio asignado'))
                              );
                              return;
                            }
                          }

                          if (printerService.selectedDeviceAddress == null) {
                            await printerService.showDeviceSelectionDialog(context);
                            if (printerService.selectedDeviceAddress == null) return;
                          } else {
                            _mostrarDialogoMontos();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Text(
                    'TOTAL C\$',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedNumber(totalVenta),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class ShowDialogMontos extends StatefulWidget {
  final Future<void> Function() impimir;
  final double montoTotal;

  const ShowDialogMontos({super.key,
    required this.montoTotal,
    required this.impimir,
  });

  @override
  _ShowDialog createState() => _ShowDialog();
}

class _ShowDialog extends State<ShowDialogMontos> {
  final TextEditingController _montoPagoController = TextEditingController();
  double _cambio = 0.0;

  void _calcularCambio() {
    final pago = double.tryParse(_montoPagoController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _cambio = pago - widget.montoTotal;
    });
  }

  @override
  void dispose() {
    _montoPagoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Total a pagar: \$${widget.montoTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoPagoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Monto recibido',
              border: OutlineInputBorder(),
              isDense: true,
              prefixText: 'C\$'
            ),
            onChanged: (value) => _calcularCambio(),
          ),
          const SizedBox(height: 16),
          Text(
            'Cambio: \$${_cambio.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              color: _cambio < 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_cambio >= 0) {
                await widget.impimir();
                Navigator.pop(context, {
                  'pago': double.tryParse(_montoPagoController.text) ?? 0.0,
                  'cambio': _cambio,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El pago es insuficiente.')),
                );
              }
            },
            child: const Text('Aceptar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              maximumSize: Size(double.infinity, 50),
              // padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
