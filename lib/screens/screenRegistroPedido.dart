import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inversiones_ar/services/geolocationServices.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:inversiones_ar/widgets/montosDialog.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';


class RegistroPedido extends ConsumerStatefulWidget {
  const RegistroPedido({super.key});

  @override
  ConsumerState<RegistroPedido> createState() => _RegistroPedidoState();
}

class _RegistroPedidoState extends ConsumerState<RegistroPedido> {
  final _formKey = GlobalKey<FormState>();
  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  List<ProductoModel> _productos = [];
  List<GenericModelCombobox> _categorias = [];
  List<GenericModelCombobox> _subCategorias = [];
  List<ClienteModel> _clientes = [];
  List<Map<String, dynamic>> detallePedido = [];
  ClienteModel? _clienteSeleccionado;
  GenericModelCombobox? _categoriaSeleccionada;
  ProductoModel? _productoSeleccionado;
  ProductoModel? _productoAdd;
  ClienteCredito? _clienteCredito;
  GenericModelCombobox? _subCatSeleccionada;
  int idAperturaCaja = 0;
  bool _esCredito = false;
  String cliente = '';
  String? tipo;
  bool isLoading = false;
  bool isStock = false;

  late Map<String, dynamic> venta = {};
  late List<Map<String, dynamic>> productos = [];
  late List<Map<String, dynamic>> productosConnected = [];
  double totalVenta = 0.0;

  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController enviarAController = TextEditingController();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController fechaEntregaSolicitud = TextEditingController();
  final TextEditingController noVentaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final Map<int, TextEditingController> _precioControllers = {};

  List<DireccionesClientes> direcciones = [];
  DireccionesClientes? _direccionSeleccionada;

  Future<void> loadProductos(int idSubCategoria) async {
    try {
      setState(() {
        _productos = [];
      });
      final List<ProductoModel> productos = await getProducts(idSubCategoria);

      setState(() {
        _productos = productos;
      });
    } catch (e) {
      throw showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Fallo a l cargar productos'),
              content: Text(e.toString()
              ),
            );
          }
      );
    }
  }

  Future<void> getCategoriaProducto() async {
    try {
      final categorias = await getCategoriaProductos();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
      });
    } catch(e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Fallo al cargar las categorias'),
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

  Future<void> getSubCatProducto(int idCategoria) async {
    try {
      final subcategorias = await getSubCategoriaProductos(idCategoria);
      print(subcategorias[0].toString());
      if (!mounted) return;
      setState(() {
        _subCategorias = subcategorias;
      });
    } catch(e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Fallo al cargar las subcategorías'),
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

  Future<void> getProductoId(int idProducto) async {
    try {
      final response = await getProductoById(idProducto);
      setState(() {
        _productoAdd = response;
      });
    } catch(e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sin informacion'),
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

  Future<void> setCreditoCliente(int idCliente) async {
    try {
      setState(() {
        _clienteCredito = null;
        _esCredito = false;
      });

      final cliente = await getCreditoCliente(idCliente);

      final esCredito =
          cliente.esCreditoIlimitado == true ||
              (
                  cliente.esTieneCredito == true &&
                      cliente.creditoDisponible > 0
              );

      setState(() {
        _clienteCredito = cliente;
        _esCredito = esCredito;
      });

    } catch (e) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Fallo al cargar crédito'),
            content: Text(e.toString()),
          );
        },
      );
    }
  }



  bool verifyData() {
    if(noVentaController.text.isEmpty ||
        clienteController.text.isEmpty ||
        '${_direccionSeleccionada?.nombre}: ${_direccionSeleccionada?.direccionIngresada}'.isEmpty ||
        observacionesController.text.isEmpty ||
        detallePedido.isEmpty
    ) {
      return false;
    }
    return true;
  }

  Future<void> _getClienteById(int idCliente) async {
    try {
      final response = await getClienteById(idCliente);
      setState(() {
        _clienteSeleccionado = response;
        direcciones = response.direcciones ?? [];
      });
    } catch(e) {
      if (!mounted) return;
    }
  }

  Future<void> _imprimirFactura() async {
    String nombreUsuario = ref.read(authProvider).userPayload?.usuario ?? 'Usuario Desconocido';
    int idAperturaCaja = ref.read(authProvider).idAperturaCaja;
    late String location;

    if(!mounted) return;

    if(isConnected) {
      try {
        isLoading = true;
        LoadingOverlay.show(context, message: 'Obteniendo ubicación...');

        String localidad = 'Ubicación no disponible';
        try {
          Position position = await getCurrentLocation();
          print('POSICION: ${position.toString()}');
          localidad = await getLocalidad(position);
          print('LOCALIDAD: $localidad');
          LoadingOverlay.show(context, message: 'Ubicación obtenida');
          Future.delayed(const Duration(milliseconds: 500), () {});
        } catch (e) {
          LoadingOverlay.show(context, message: 'Ubicación no disponible');
          Future.delayed(const Duration(milliseconds: 500), () {});
          print('No se pudo obtener ubicación, se continúa sin ella: $e');
          // localidad se queda en 'Ubicación no disponible'
        }

        setState(() {
          location = localidad;
          productosConnected.clear();

          for (var item in detallePedido) {
            if (item['idProducto'] != null && item['nombre'] != null) {
              productosConnected.add({
                "idProducto": item['idProducto'],
                "cantidad": item['cantidad'],
                "observaciones": "Sin detalles"
              });
            }
          }

          productos.clear();

          for (var item in detallePedido) {
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
          // "noVenta": noVentaController.text,
          "idCliente": _clienteSeleccionado?.nombre,
          // "idCliente": clienteController.text,
          "enviarA": '${_direccionSeleccionada?.nombre}: ${_direccionSeleccionada?.direccionIngresada}',
          "fechaRegistro": new DateTime.now().toString(),
          "ubicacion": location,
          "observaciones": observacionesController.text,
          "credito": _esCredito,
          "usuarioRegistro": productosConnected
        };

        isLoading = true;
        LoadingOverlay.show(context, message: 'Registrando pedido...');
        final result = await postPedidos({
          "idAperturaCaja": idAperturaCaja,
          "idCliente": _clienteSeleccionado?.idCliente,
          "isSolicitudCredito": _esCredito,
          "fechaEntregaSolicitada": fechaEntregaSolicitud.text,
          "observaciones": observacionesController.text,
          "ubicacion": location,
          "enviarA": '${_direccionSeleccionada?.nombre}: ${_direccionSeleccionada?.direccionIngresada}',
          "usuarioRegistro": nombreUsuario,
          "detallePedido": productosConnected
        });
        LoadingOverlay.hide();
        isLoading = false;

        if(result?['code'] != 400 && result?['code'] != 404 && result?['code'] != 400.1) {
          ToastSnackBar.show(
            context,
            type: ToastType.success,
            message: 'Pedido registrado con éxito. \nNo. Pedido: ${result?['noPedido']}',
          );
          _clearData();
        } else {
          ToastSnackBar.show(
            context,
            type: ToastType.error,
            message: result?['msg'] ?? 'Error al registrar la venta',
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        LoadingOverlay.hide();
        isLoading = false;
        // Navigator.of(context, rootNavigator: true).pop();
        ToastSnackBar.show(
          context,
          type: ToastType.error,
          message: e.toString(),
        );
      }
    }
  }

  void agregarProducto({
    required GenericModelCombobox? categoria,
    required ProductoModel? producto,
    required double cantidad,
  }) {
    if (producto == null) return;

    final double precio = producto.precio ?? 0;
    final double totalCalculado = cantidad * precio;

    setState(() {
      final int existIndex = detallePedido.indexWhere(
              (item) => item['idProducto'] == producto.idProducto
      );

      if(existIndex != -1) {
        final double cantidadActual = (detallePedido[existIndex]['cantidad'] as num).toDouble();
        final double nuevCantidad = cantidadActual + cantidad;

        if(producto.precioMayorista == null) return;

        if(producto.esMayorista && producto.precioMayorista!.isNotEmpty) {
          for (var item in producto.precioMayorista!) {
            if (nuevCantidad >= item.minimo && nuevCantidad <= item.maximo) {
              final double total = nuevCantidad * item.precio;
              detallePedido[existIndex]['precioUnitario'] = item.precio;
              detallePedido[existIndex]['cantidad'] = nuevCantidad;
              detallePedido[existIndex]['total'] = total;
            }
          }
        } else {
          detallePedido[existIndex]['cantidad'] = nuevCantidad;
          detallePedido[existIndex]['total'] = nuevCantidad * precio;
        }
      } else {
        if(producto.precioMayorista == null) return;

        if(producto.esMayorista && producto.precioMayorista!.isNotEmpty) {
          for (var item in producto.precioMayorista!) {
            if (cantidad >= item.minimo && cantidad <= item.maximo) {
              final double total = cantidad * item.precio;
              detallePedido.add({
                'id': DateTime.now().microsecondsSinceEpoch,
                'tipoProducto': categoria?.nombre ?? '',
                'idProducto': producto.idProducto ?? 0,
                'nombre': producto.nombre ?? '',
                'precioUnitario': item.precio,
                'cantidad': cantidad,
                'total': total,
              });
            }
          }
        } else {
          detallePedido.add({
            'id': DateTime.now().microsecondsSinceEpoch,
            'tipoProducto': categoria?.nombre ?? '',
            'idProducto': producto.idProducto ?? 0,
            'nombre': producto.nombre ?? '',
            'precioUnitario': precio,
            'cantidad': cantidad,
            'total': totalCalculado,
          });
        }

      }
    });

    actualizarTotal();
  }

  void actualizarTotal() {
    double total = 0.0;
    for (var item in detallePedido) {
      final cantidad = double.tryParse(item['cantidad'].toString()) ?? 0;
      final precio = double.tryParse(item['precioUnitario'].toString()) ?? 0;
      total += cantidad * precio;
    }

    setState(() {
      totalVenta = total;
    });
  }

  void _addProducto(BuildContext context) async {
    LoadingOverlay.show(context, message: 'Cargando datos...');
    await getCategoriaProducto();
    LoadingOverlay.hide();

    final formKey = GlobalKey<FormState>();
    bool existSubCat = false;
    bool existProd = false;
    String? _mensajeErrorStock;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
              builder: (contex, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                  actions: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _cantidadController.clear();
                                _productoSeleccionado = null;
                                _subCatSeleccionada = null;
                                _categoriaSeleccionada = null;
                                _productos = [];
                                _categorias = [];
                                _subCategorias = [];
                              });
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              if(formKey.currentState!.validate()) {
                                if (!mounted) return;

                                if (_productoAdd == null) {
                                  _mensajeErrorStock = 'Seleccione un producto';
                                  return;
                                }
                                final double cantidadIngresada = double.tryParse(_cantidadController.text) ?? 0;
                                final double stockDisponibleTotal = _productoAdd?.cantidadTotal ?? 0;

                                final int existIndex = detallePedido.indexWhere((item) => item['idProducto'] == (_productoAdd!.idProducto)
                                );

                                double cantidadPrevia = 0;
                                if (existIndex != -1) {
                                  cantidadPrevia = (detallePedido[existIndex]['cantidad'] as num).toDouble();
                                }

                                final double stockRestante = stockDisponibleTotal - cantidadPrevia;
                                // if (cantidadIngresada > stockRestante) {
                                //   setDialogState(() {
                                //     _mensajeErrorStock = stockRestante > 0
                                //         ? 'Solo quedan ${stockRestante.toStringAsFixed(0)} unidades disponibles'
                                //         : 'Ya agregaste todo el stock disponible de este producto';
                                //   });
                                //   return;
                                // }

                                final catActual = _categoriaSeleccionada;

                                agregarProducto(
                                  categoria: catActual,
                                  producto: _productoAdd,
                                  cantidad: cantidadIngresada,
                                );

                                setState(() {
                                  _categoriaSeleccionada = null;
                                  _subCatSeleccionada = null;
                                  _productoSeleccionado = null;
                                  _productoAdd = null;
                                  _subCategorias = [];
                                  _productos = [];
                                });

                                _cantidadController.clear();

                                Navigator.of(context).pop();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              foregroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Agregar',
                              style: TextStyle(
                                color: Colors.indigo,

                              ),
                            ),
                          )
                        ]
                    )
                  ],
                  iconPadding: const EdgeInsets.all(16),
                  title: const Text(
                    'Agregar Producto',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Categorias', ),
                          const SizedBox(height: 4),
                          DropdownFlutter<GenericModelCombobox>.search(
                            enabled: true,
                            key: ValueKey('cat_${_categorias.length}'),
                            initialItem: _categoriaSeleccionada,
                            hintText: 'Seleccione una categoria',
                            decoration: const CustomDropdownDecoration(
                              expandedFillColor: Colors.white,
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              headerStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              prefixIcon: Icon(Icons.category, color: Colors.grey),

                              // Bordes
                              closedBorder: Border(
                                top: BorderSide(
                                  color: Colors.grey,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey,
                                ),
                                left: BorderSide(
                                  color: Colors.grey,
                                ),
                                right: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),

                              closedSuffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                              expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.indigo),
                            ),
                            items: _categorias,
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
                            validator: (value) => value == null ? 'Seleccione una categoria' : null,
                            onChanged: (value) async {
                              if (value == null) return;

                              if (!mounted) return;
                              await getSubCatProducto(value.id ?? 0);

                              setDialogState(() {
                                _categoriaSeleccionada = value;
                                _subCatSeleccionada = null;
                                _productoSeleccionado = null;
                                _productos = [];

                                existSubCat = _subCategorias.isEmpty ? false : true;;
                              });

                                                        },
                          ),

                          const SizedBox(height: 16),

                          const Text('Subcategorias', ),
                          const SizedBox(height: 4),
                          DropdownFlutter<GenericModelCombobox>.search(
                            enabled: existSubCat,
                            key: ValueKey('subcat_${_subCategorias.length}'),
                            initialItem: _subCatSeleccionada,
                            hintText: 'Seleccione una subcategoria',
                            decoration: const CustomDropdownDecoration(
                              expandedFillColor: Colors.white,
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              headerStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              prefixIcon: Icon(Icons.category_outlined, color: Colors.grey),

                              // Bordes
                              closedBorder: Border(
                                top: BorderSide(
                                  color: Colors.grey,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey,
                                ),
                                left: BorderSide(
                                  color: Colors.grey,
                                ),
                                right: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),

                              closedSuffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                              expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.indigo),
                            ),
                            items: _subCategorias,
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
                            validator: (value) => value == null ? 'Seleccione una subcategoria' : null,
                            onChanged: (value) async {
                              if (value == null) return;

                              if (!mounted) return;
                              await loadProductos(value.id ?? 0);

                              setDialogState(() {
                                _productoSeleccionado = null;
                                _subCatSeleccionada = value;

                                existProd = _productos.isEmpty ? false : true;
                              });

                                                        },
                          ),

                          const SizedBox(height: 16),

                          const Text('Productos', ),
                          const SizedBox(height: 4),
                          DropdownFlutter<ProductoModel>.search(
                            enabled: existProd,
                            key: ValueKey('prod_${_productos.length}'),
                            initialItem: _productoSeleccionado,
                            hintText: 'Seleccione un producto',
                            decoration: const CustomDropdownDecoration(
                              prefixIcon: Icon(Icons.production_quantity_limits, color: Colors.grey),
                              // Bordes
                              closedBorder: Border(
                                top: BorderSide(
                                  color: Colors.grey,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey,
                                ),
                                left: BorderSide(
                                  color: Colors.grey,
                                ),
                                right: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),

                              closedSuffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                              expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey),
                            ),
                            items: _productos
                                .map<ProductoModel>((producto) => producto).toList(),
                            headerBuilder: (context, selectedItem, enabled) {
                              return Text(
                                selectedItem.nombre ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              );
                            },
                            listItemBuilder: (context, item, isSelected, onItemSelected) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.nombre ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${item.cantidadTotal ?? 0} | Precio: C\$ ${item.precio ?? 0}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              );
                            },
                            validateOnChange: true,
                            validator: (value) => value == null ? 'Seleccione un producto' : null,
                            onChanged: (value) async {
                              if (value == null) return;

                              final double stockTotal = value.cantidadTotal ?? 0;

                              if (stockTotal <= 0) {
                                setDialogState(() {
                                  _mensajeErrorStock = 'No hay stock disponible para este producto';
                                  _productoSeleccionado = null;
                                });
                                return;
                              }

                              // Verificar si ya se agregó todo el stock al carrito
                              final int existIndex = detallePedido.indexWhere(
                                    (item) => item['idProducto'] == (value.idProducto ?? 0),
                              );

                              if (existIndex != -1) {
                                final double cantidadEnCarrito = (detallePedido[existIndex]['cantidad'] as num).toDouble();

                                if (cantidadEnCarrito >= stockTotal) {
                                  setDialogState(() {
                                    _mensajeErrorStock = 'Ya has agregado todo el stock disponible al detalle';
                                    _productoSeleccionado = null;
                                  });
                                  return;
                                }
                              }

                              await getProductoId(value.idProducto ?? 0);

                              setDialogState(() {
                                _mensajeErrorStock = null;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          const Text('Cantidad', ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese la cantidad';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          if (_mensajeErrorStock != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _mensajeErrorStock!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void eliminarProducto(int index) {
    setState(() {
      detallePedido.removeAt(index);
      _precioControllers.remove(index);
    });
    actualizarTotal();
  }

  void calcularTotalItem(int index) {
    final cantidad = double.tryParse(detallePedido[index]['cantidad'].toString()) ?? 0;
    final precio = double.tryParse(detallePedido[index]['precioUnitario'].toString()) ?? 0;
    final total = cantidad * precio;
    setState(() {
      detallePedido[index]['total'] = total;
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
          isLoaded: isLoading,
        ),
      ),
    );
  }

  void _clearData() {
    setState(() {
      noVentaController.clear();
      clienteController.clear();
      enviarAController.clear();
      observacionesController.clear();
      fechaEntregaSolicitud.clear();
      _cantidadController.clear();
      detallePedido.clear();
      _esCredito = false;
      totalVenta = 0.0;
      _clienteSeleccionado = null;

    });
  }

  Future<int> _getNumeroVenta() async {
    final int numFact = await getNumFact();
    return numFact;
  }

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  final ScrollController _scrollController = ScrollController();
  bool _showShadowBottom = true;

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
          await getCategoriaProducto();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(mounted) {
        LoadingOverlay.show(context, message: 'Cargando datos...');
        await loadClientes();
        await getCategoriaProducto();
        LoadingOverlay.hide();
        ref.read(printerProvider).requestBluetoothPermissions(context: context);
        idAperturaCaja = ref.read(authProvider).idAperturaCaja;
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
  Widget build(BuildContext context) {
    String title = 'Registrar Pedido';

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
      backgroundColor: Colors.white,
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
                '${title.toUpperCase()}',
                style: TextStyle(
                  fontSize: 18.0,
                  letterSpacing: 0.5,
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

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.topCenter,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (_clienteCredito?.esTieneCredito ?? false) ? Icons.credit_card : Icons.payments,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _esCredito ? 'CRÉDITO' : 'CONTADO',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),

                        IgnorePointer(
                          child: Switch(
                            value: _esCredito,
                            onChanged: (_) {},
                            activeColor: const Color(0xff1a237e),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- SECCIÓN: CLIENTE ---
                  TypeAheadField(
                    key: ValueKey(_clienteSeleccionado?.idCliente),
                    suggestionsCallback: (search) {
                      return _clientes.where((cliente) {
                        return cliente.nombre.toLowerCase().contains(search.toLowerCase());
                      }).toList();
                    },
                    builder: (context, controller, focusNode) {
                      // Si ya hay un cliente seleccionado, precargamos su nombre en el buscador
                      if (_clienteSeleccionado != null && controller.text.isEmpty) {
                        controller.text = _clienteSeleccionado!.nombre;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Cliente',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Elija un cliente',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.person_search, color: Colors.grey),
                          suffixIcon: _clienteSeleccionado != null
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              controller.clear();
                              setState(() => _clienteSeleccionado = null);
                            },
                          )
                              : const Icon(Icons.search, color: Colors.grey,),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        style: TextStyle(
                            color: Colors.grey[600],
                            height: 2
                        ),
                        cursorHeight: 25,
                      );
                    },
                    itemBuilder: (context, cliente) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        title: Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(cliente.departamento ?? 'Sin departamento'),
                      );
                    },
                    onSelected: (cliente) async {
                      // 1. Primero actualizas el cliente seleccionado
                      if (cliente.idCliente != null) {
                        await Future.wait([
                          _getClienteById(cliente.idCliente!),
                          setCreditoCliente(cliente.idCliente!)
                        ]);
                      }
                    },
                  ),
                  if (_clienteSeleccionado != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Departamento: ',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          Text(
                            _clienteSeleccionado?.departamento ?? '- - -',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownFlutter<DireccionesClientes>.search(
                      enabled: _clienteSeleccionado != null,
                      key: const ValueKey('cliente_direccion'),
                      items: direcciones,
                      initialItem: _direccionSeleccionada,
                      hintText: 'Seleccione una dirección',
                      excludeSelected: true,
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
                      listItemBuilder: (context, item, isSelected, onItemSelected) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nombre ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              'Dir: ${item.direccionIngresada ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            )
                          ],
                        );
                      },
                      validateOnChange: true,
                      validator: (value) => value == null ? 'Seleccione una dirección' : null,
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          _direccionSeleccionada?.nombre ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        );
                      },
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _direccionSeleccionada = value;
                          });
                        }
                      }
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: fechaEntregaSolicitud,
                    readOnly: true,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Entrega',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
                      isDense: false,
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
                        // Formateamos la fecha seleccionada.
                        // Ejemplo básico: "dd/mm/yyyy"
                        String formattedDate =
                            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                        // Asignamos la fecha al controlador para que se muestre en el campo
                        fechaEntregaSolicitud.text = formattedDate;
                      }

                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.comment_outlined, color: Colors.grey),
                      isDense: false,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      )
                    ),
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 2.5,
                    ),
                    cursorHeight: 25,
                  ),
                  const SizedBox(height: 28),

                  // --- SECCIÓN: DETALLE DE PRODUCTOS ---
                  Row(
                    children: [
                      const Icon(Icons.shopping_basket_outlined, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        "Productos",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                          ),
                          onPressed: () => _addProducto(context),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.indigo, size: 18),
                              const SizedBox(width: 4),
                              const Text(
                                "AGREGAR",
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                      )
                    ],
                  ),

                  const SizedBox(height: 8),

                  detallePedido.length == 0
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'NO HAY PRODUCTOS AGREGADOS',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ) : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detallePedido.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = detallePedido[index];

                      return Dismissible(
                        key: Key('prod_${index}_${item['id'] ?? index}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) => eliminarProducto(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade600),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.indigo.shade50,
                                child: const Icon(Icons.shopping_cart_outlined, color: Colors.indigo, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['nombre']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cant: ${item['cantidad']} • C\$ ${formattedNumber(item['precioUnitario'])} c/u',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'C\$ ${formattedNumber((item['total']))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                onPressed: () => eliminarProducto(index),
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Resumen",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                          children: [
                            const Text(
                              "Total Productos",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              'C\$ ${formattedNumber(totalVenta)}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ]
                      ),
                      const SizedBox(height: 8),
                      Row(
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              'C\$ ${formattedNumber(totalVenta)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ]
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
          height: 70,
          color: Colors.white,
          elevation: _showShadowBottom ? 32 : 0,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.grey[200],
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: SizedBox.expand(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  backgroundColor: Color(0xff1a237e),
                  alignment: Alignment.center,
                ),
                onPressed: () async {
                  if(_clienteSeleccionado == null) {
                    ToastSnackBar.show(
                      context,
                      message: 'Seleccione un cliente',
                      type: ToastType.warning,
                    );
                    return;
                  }

                  if(detallePedido.isEmpty) {
                    ToastSnackBar.show(
                      context,
                      message: 'Agregue productos a la venta',
                      type: ToastType.warning,
                    );
                    return;
                  }

                  if (_esCredito) {
                    if (_clienteCredito == null) {
                      ToastSnackBar.show(
                        context,
                        message: 'No se ha podido cargar la información de crédito del cliente',
                        type: ToastType.error,
                      );
                      return;
                    }

                    if (_clienteCredito!.esCreditoIlimitado != true) {
                      if (totalVenta > _clienteCredito!.creditoDisponible) {
                        ToastSnackBar.show(
                          context,
                          message: 'El total de la venta (C\$ ${formattedNumber(totalVenta)}) supera el crédito disponible (C\$ ${formattedNumber(_clienteCredito!.creditoDisponible)})',
                          type: ToastType.error,
                        );
                        return;
                      }
                    }
                  }

                  for(var item in detallePedido) {
                    if(item['precioUnitario'] == null || item['precioUnitario'] <= 0 ) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('El producto ${item['nombre']} no tiene precio asignado'))
                      );
                      return;
                    }
                  }
                  _imprimirFactura();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Registrar Pedido",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
            ),
          )
      ),
    );
  }
}