import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:provider/provider.dart';
import 'package:inversiones_ar/dbHelper/dbHelper.dart' as db;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

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
    print('PRODUCTOS: ${detalleVenta.toList().toString()}');
    final printerService = context.read<PrinterService>();
    if(printerService.isPrinting || printerService.isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya se está imprimiendo una factura.'))
      );
      return;
    }

    if(!mounted) return;

    if(printerService.selectedDeviceAddress == null) {
      await printerService.showDeviceSelectionDialog(context);
      if(printerService.selectedDeviceAddress == null) return;
    }

    for(var item in detalleVenta) {
      print(item.toString());
      if(item['precioUnitario'] == null || item['precioUnitario'] <= 0 ) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El producto ${item['nombre']} no tiene precio asignado'))
        );
        return;
      }
    }

    if(isConnected) {
      print('CONECTADO');
      setState(() {
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

      if(productos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrese uno o mas productos a facturar.'))
        );
        return;
      }
      venta = {
        "noVenta": noVentaController.text,
        "idCliente": _clienteSeleccionado?.codigo,
        // "idCliente": clienteController.text,
        "enviarA": enviarAController.text,
        "fechaRegistro": new DateTime.now().toString(),
        "observaciones": observacionesController.text,
        "credito": _esCredito,
        "usuarioRegistro": productosConnected
      };

      final result = await postVentas({
        "noVenta": noVentaController.text.toString(),
        "idCliente": _clienteSeleccionado?.idCliente,
        "credito": _esCredito,
        "observaciones": observacionesController.text,
        "enviarA": enviarAController.text,
        "usuarioRegistro": 'admin',
        "detalleVenta": productosConnected
      });

      if(result?['code'] == 201 ) {
        final nuevaVenta = VentaModel(
            noVenta: noVentaController.text,
            idCliente: _clienteSeleccionado?.idCliente ?? 0,
            credito: _esCredito,
            cliente: _clienteSeleccionado?.codigo ?? '',
            sincronizada: true,
            observaciones: observacionesController.text,
            enviarA: enviarAController.text,
            fechaRegistro: new DateTime.now().toString(),
            usuarioRegistro: 'admin',
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

        await db.DbHelper().registrarVenta( nuevaVenta,  detalle);
        final bool success = await printerService.imprimirFactura(
          context: context,
          venta: venta,
          productos: productos,
          ivaPorcentaje: 15,
          tipoCambio: 36.6243,
        );

        if(success) {
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
      setState(() {
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
          observaciones: observacionesController.text,
          enviarA: enviarAController.text,
          fechaRegistro: new DateTime.now().toString(),
          usuarioRegistro: 'admin',
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

        await db.DbHelper().registrarVenta( nuevaVenta,  detalle);
        final bool success = await printerService.imprimirFactura(
          context: context,
          venta: venta,
          productos: productos,
          ivaPorcentaje: 15,
          tipoCambio: 36.6243,
        );
        if(success) {
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


  @override
  void initState() {
    super.initState();
     _clientes = getClientes();
     _clientesLocalFuture = getClientesLocales();
     getTipoProductos();
     getClientesLocales();

     connectionChecker.hasConnection.then((value) => {
       if(mounted) {
         setState(() {
           isConnected = value;
         })
       }
     });

     _connectionStatus = connectionChecker.onStatusChange.listen((status) {
       if(mounted) {
         setState(() {
           isConnected = status == InternetConnectionStatus.connected;
         });
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
    final estiloInput = InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            controller: noVentaController,
                            decoration: const InputDecoration(
                                labelText: 'No. Venta',
                                isDense: true
                            )
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<ClienteModel>>(
                      future: isConnected ?  _clientes : _clientesLocalFuture,
                      builder: (context, snapshot) {
                        if(isConnected) {
                          if(snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if(snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if(snapshot.hasData && snapshot.data!.isEmpty) {
                            return Text('No hay clientes registrados');
                          }
                        }

                        final clientes = snapshot.data!;

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
                          }).toList()
                        );
                      }
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      title: Text(_esCredito ? 'Venta a crédito' : 'Contado'),
                      dense: true,
                      activeColor: Colors.indigo,
                      value: _esCredito,
                      onChanged: (v) => setState(() => _esCredito = v),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          isDense: true
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: enviarAController,
                      decoration: const InputDecoration(
                          labelText: 'Enviar a',
                          isDense: true
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const Text("Detalle de productos", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    ...detalleVenta.asMap().entries.map((entry) {
                      final index = entry.key;
                      final producto = entry.value;
                      final productos = isConnected ? _productos : _productosLocales;
                      final uniqueProductos = productos.toSet().toList();
                      final uniqueTiposProductos = _tiposProductos.toSet().toList();

                      return Card(
                        color: Colors.white,
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(labelText: 'Selecciona un tipo de producto'),
                                isDense: true,
                                isExpanded: true,
                                // value: producto['tipoProducto'].toString(),
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

                                  // Cargar productos del tipo seleccionado
                                  List<ProductoModel> productosFiltrados;
                                  if (isConnected) {
                                    productosFiltrados = await getProductos(value.toString());
                                  } else {
                                    final dbHelper = db.DbHelper();
                                    final local = await dbHelper.getProductos(value.toString());
                                    productosFiltrados = local;
                                  }

                                  setState(() {
                                    producto['productosFiltrados'] = productosFiltrados;
                                  });
                                },
                                validator: (value) => value == null ? 'Seleccione un tipo de producto' : value,
                                items: uniqueTiposProductos.map((tipo) {
                                  return DropdownMenuItem<String>(
                                    value: tipo.nombre,
                                    child: Text(tipo.nombre.toString()),
                                  );
                                }).toList()
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: producto['idProducto'] == 0 ? null : producto['idProducto'].toString(),
                                hint: const Text("Producto"),
                                isExpanded: true,
                                onChanged: (value) {
                                  setState(() {
                                    print('PRODUCTOOOOOO $value');
                                    final p = producto['productosFiltrados'][1];
                                    print('${p.nombre}, $value');
                                    final selected = producto['productosFiltrados'].firstWhere(
                                          (p) => p.idProducto.toString() == value.toString()
                                    );

                                    if (selected != null) {
                                      producto['idProducto'] = selected.idProducto;
                                      producto['nombre'] = selected.nombre;
                                      producto['precioUnitario'] = selected.precio;
                                      producto['total'] = selected.precio * producto['cantidad'];
                                    }
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
                                      decoration: const InputDecoration(labelText: 'Cantidad'),
                                      onChanged: (value) {
                                        detalleVenta[index]['cantidad'] = double.tryParse(value) ?? 1;
                                        calcularTotalItem(index);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: producto['precioUnitario'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Precio U'),
                                      onChanged: (value) {
                                        print('Precio del producto $value');
                                        final precio = double.tryParse(value);
                                        if (precio != null) {
                                          detalleVenta[index]['precioUnitario'] = precio;
                                          print(detalleVenta[index]);
                                          calcularTotalItem(index);
                                        } else {
                                          print("Precio inválido: '$value'");
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
                                    icon: const Icon(Icons.delete, color: Colors.indigo),
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
                          side: const BorderSide(color: Colors.indigo),
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
                        onPressed: () => _imprimirFactura(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Text('TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(Icons.attach_money, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    totalVenta.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            )
          )
        ]
      )
    );
  }
}
