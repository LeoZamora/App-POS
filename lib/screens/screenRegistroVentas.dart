import 'package:flutter/material.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/services/servicesPrinter.dart';
import 'package:provider/provider.dart';

class RegistroVentas extends StatefulWidget {
  const RegistroVentas({super.key});

  @override
  State<RegistroVentas> createState() => _RegistroVentasState();
}

class _RegistroVentasState extends State<RegistroVentas> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<ClienteModel>> _clientes;
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController enviarAController = TextEditingController();
  late Map<String, dynamic> venta = {};
  late List<Map<String, dynamic>> productos = [];

  ClienteModel? _clienteSeleccionado;
  bool _esCredito = false;

  final List<Map<String, dynamic>> productosDisponibles = [
    {'name': 'Anillo Plata', 'value': 1},
    {'name': 'Pulsera Acero', 'value': 2},
    {'name': 'Collar Oro', 'value': 3},
  ];

  Future<void> _imprimirFactura() async {
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

    setState(() {
      productos.clear();

      detalleVenta.forEach((item) {
        productos.add({
          "nombre": item['nombre'],
          "cantidad": item['cantidad'],
          "precio": item['precioUnitario'],
        });
      });
    });

    venta = {
      "NoVenta": 1,
      "IdCliente": _clienteSeleccionado?.codigo,
      "FechaRegistro": "2023-07-05T00:00:00",
      "Observaciones": observacionesController.text,
    };

    print('VENTA: $venta');
    print('PRODUCTOS: ${productos}');
    print('Detalles: ${detalleVenta}');

    if(productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese uno o mas productos a facturar.'))
      );
      return;
    } else {
      print('PRODUCTOS: $productos');
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

  List<Map<String, dynamic>> detalleVenta = [];
  void agregarProducto() {
    setState(() {
      detalleVenta.add({
        'nombre': '',
        'cantidad': 1,
        'precioUnitario': 0.0,
        'total': 0.0,
      });
    });
  }

  void eliminarProducto(int index) {
    setState(() {
      detalleVenta.removeAt(index);
    });
  }

  void calcularTotalItem(int index) {
    final cantidad = double.tryParse(detalleVenta[index]['cantidad'].toString()) ?? 0;
    final precio = double.tryParse(detalleVenta[index]['precioUnitario'].toString()) ?? 0;
    final total = cantidad * precio;
    setState(() {
      detalleVenta[index]['total'] = total;
    });
  }

  @override
  void initState() {
    super.initState();
     _clientes = getClientes();
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
      body: Theme(
        data: Theme.of(context).copyWith(inputDecorationTheme: estiloInput),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cliente", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                FutureBuilder<List<ClienteModel>>(
                  future: _clientes,
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if(snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if(snapshot.hasData && snapshot.data!.isEmpty) {
                      return Text('No hay clientes registrados');
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: (producto['nombre']?.isNotEmpty ?? false) ? producto["nombre"] : null,
                            hint: const Text("Producto"),
                            onChanged: (value) {
                              setState(() {
                                detalleVenta[index]['nombre'] = value;
                              });
                            },
                            validator: (value) => value == null ? 'Seleccione un producto' : value,
                            items: productosDisponibles.map((prod) {
                              return DropdownMenuItem(
                                value: prod['name'].toString(),
                                child: Text(prod['name'].toString()),
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
                                    detalleVenta[index]['precioUnitario'] =
                                        double.tryParse(value) ?? 0;
                                    calcularTotalItem(index);
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
    );
  }
}
