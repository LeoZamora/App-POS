// import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'dart:typed_data';
import 'package:flutter/services.dart';

class PrinterService with ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // GETTERS
  List<Map<String, dynamic>> get pairedDevices => _pairedDevices;
  String? get selectedDeviceAddress => _selectedDeviceAddress;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  bool get isPrinting => _isPrinting;

  static const platform = MethodChannel("printer_channel");
  List<Map<String, String>> _pairedDevices = [];
  String? _selectedDeviceAddress;
  bool _isConnecting = false;
  String _connectionStatus = "Desconectado";
  bool _isPrinting = false;

  void _showSnackBar(BuildContext context, String message) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)));
    }
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/imgs/zafiro2.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      print("Error cargando el logo: $e");
      return null;
    }
  }

  String generarTextoFacturaConDetalle({
    required Map<String, dynamic> venta,
    required List<Map<String, dynamic>> productos,
    double ivaPorcentaje = 15,
    double tipoCambio = 36.6243,
  }) {
    final buffer = StringBuffer();

    double subtotal = 0;
    for (var p in productos) {
      subtotal += p['cantidad'] * p['precio'];
    }
    double iva = subtotal * (ivaPorcentaje / 100);
    double total = subtotal + iva;

    buffer.writeln('       Tel: +505 8888-8888       '.toString());
    buffer.writeln('Factura No:                ${venta["NoVenta"].toString().padLeft(5, '0')}');
    buffer.writeln('Cliente :                  ${venta["IdCliente"].toString()}');
    buffer.writeln('Fecha:                ${venta["FechaRegistro"]?.substring(0, 10)}');
    buffer.writeln('');
    buffer.writeln('Descripcion:');
    buffer.writeln('${venta["Observaciones"] ?? "- - -"}');
    buffer.writeln('-------------------------------');
    buffer.writeln('Cant| Producto        | Total');
    buffer.writeln('-------------------------------');
    for (var p in productos) {
      final cant = p['cantidad'].toString().padLeft(1).substring(0, 1);
      final nombre = (p['nombre'] as String).padRight(16).substring(0, 16);
      final totalLinea = (p['cantidad'] * p['precio'])
          .toStringAsFixed(2)
          .padLeft(6)
          .substring(0, 6);

      buffer.writeln('$cant | $nombre  | C\$$totalLinea');
    }

    final String symbolCor = 'C${String.fromCharCode(36)}';
    final String symbolDolar = String.fromCharCode(36);

    buffer.writeln('');
    buffer.writeln('SUBTOTAL    $symbolCor:         ${subtotal.toStringAsFixed(2).padLeft(8)}');
    buffer.writeln('IVA ($ivaPorcentaje%)   :         ${iva.toStringAsFixed(2).padLeft(8)}');
    buffer.writeln('TOTAL       $symbolCor:         ${total.toStringAsFixed(2).padLeft(8)}');
    buffer.writeln('TOTAL        $symbolDolar:        ${(total / tipoCambio).toStringAsFixed(2).padLeft(9)}');
    buffer.writeln('Tipo Cambio $symbolCor:         ${tipoCambio.toStringAsFixed(2).padLeft(8)}');

    buffer.writeln('');
    buffer.writeln('| !Gracias por su preferencia! |');
    buffer.writeln('|      www.minegocio.com       |');
    buffer.writeln('');


    return buffer.toString();
  }

  Future<bool> checkBluetoothPermissions({BuildContext? context}) async {
    try {
      final bool? granted = await platform.invokeMethod("checkBluetoothPermissions");
      if (granted == false && context != null) {
        _showSnackBar(context, "Los permisos de Bluetooth son necesarios. Por favor, concédelos en los ajustes de la app.");
      }
      return granted ?? false;
    } on PlatformException catch (e) {
      print("Error al verificar permisos de Bluetooth: ${e.message}");
      if (context != null) {
        _showSnackBar(context, "Error al verificar permisos: ${e.message}");
      }
      return false;
    }
  }

  Future<bool> requestBluetoothPermissions({BuildContext? context}) async {
    try {
      bool initiallyGranted = await checkBluetoothPermissions(context: null);
      if (initiallyGranted) {
        if (context != null) return true;
      }

      final String? resultMessage = await platform.invokeMethod("requestBluetoothPermissions");
      print("Resultado de la solicitud de permisos: $resultMessage");

      await Future.delayed(const Duration(milliseconds: 500));

      bool ultimatelyGranted = await checkBluetoothPermissions(context: context);

      if (ultimatelyGranted) {
        if (context != null) _showSnackBar(context, "Permisos de Bluetooth concedidos.");
      }
      return ultimatelyGranted;
    } on PlatformException catch (e) {
      print("Error al solicitar permisos de Bluetooth: ${e.message}");
      // if (context != null) {
      //   _showSnackBar(context, "Error al solicitar permisos: ${e.message}");
      // }
      return false;
    }
  }


  Future<void> getPairedDevices(BuildContext context) async {
    bool permissionsGranted = await requestBluetoothPermissions(context: context);
    if (!permissionsGranted) return;

    try {
      final List<dynamic>? devices = await platform.invokeMethod("getPairedDevices");
      if (devices != null) {
        _pairedDevices = devices.map((device) => Map<String, String>.from(device as Map)).toList();
        notifyListeners();
      } else {
        _pairedDevices = [];
        notifyListeners();
        // String msgError = "No se encontraron dispositivos vinculados.";
        // _showSnackBar(context, msgError);
      }
    } on PlatformException catch (e) {
      _showSnackBar(context, 'Error al obtener dispositivos: ${e.message}');
      _pairedDevices = [];
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BuildContext context, String address) async { // Pasa BuildContext
    if (_isConnecting) return;
    _isConnecting = true;
    _connectionStatus = "Conectando a ${address}...";
    _showSnackBar(context, _connectionStatus);
    notifyListeners();
    try {
      final String? result = await platform.invokeMethod("connectToDevice", {"address": address});
      _connectionStatus = result ?? "Conectado";
      _selectedDeviceAddress = address;
      _showSnackBar(context, result ?? "Conectado exitosamente");
    } on PlatformException catch (e) {
      _connectionStatus = "Error de conexión: ${e.message}";
      _showSnackBar(context, "Error al conectar: ${e.message}");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice(BuildContext context) async {
    if (_selectedDeviceAddress == null) return;
    try {
      await platform.invokeMethod("disconnectDevice");
      _connectionStatus = "Desconectado";
      _selectedDeviceAddress = null;
      notifyListeners();
      _showSnackBar(context, "Desconectado de la impresora.");
    // } on PlatformException catch (e) {
      // _showSnackBar(context, "Error al desconectar: ${e.message}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> showDeviceSelectionDialog(BuildContext context) async {
    await getPairedDevices(context);
    if (!Navigator.of(context).mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text("Selecciona una impresora"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _pairedDevices.isEmpty
                ? Text(
                "No hay impresoras vinculadas. \nAsegúrate de vincular tu impresora en los ajustes de Bluetooth del dispositivo.")
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _pairedDevices.length,
              itemBuilder: (context, index) {
                final device = _pairedDevices[index];
                return ListTile(
                  title: Text(device["name"] ?? "Dispositivo desconocido"),
                  textColor: selectedDeviceAddress == device["address"] ? Colors.indigo : Colors.black,
                  subtitle: Text(device["address"] ?? ""),
                  dense: true,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    connectToDevice(context, device["address"]!);
                  },
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      disconnectDevice(context);
                    },
                    child: Icon(
                      Icons.print_disabled_outlined,
                      color: selectedDeviceAddress == device['address'] ? Colors.red : Colors.transparent,
                      size: 20.0,
                    )
                  ),
                  trailing: Icon(
                    Icons.check_circle_outline,
                    color: selectedDeviceAddress == device['address'] ? Colors.indigo : Colors.transparent,
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancelar"),
            )
          ],
        );
      }
    );
  }


  Future<bool> imprimirFactura({
    required BuildContext context,
    required Map<String, dynamic> venta,
    required List<Map<String, dynamic>> productos,
    double ivaPorcentaje = 15,
    double tipoCambio = 36.6243,
  }) async {
    if (_selectedDeviceAddress == null) {
      _showSnackBar(context, "Por favor, selecciona y conecta una impresora primero.");
      await showDeviceSelectionDialog(context);
      if(_selectedDeviceAddress == null) return false;
    }

    if (_isPrinting) return false;
    _isPrinting = true;
    notifyListeners();

    try {
      Uint8List? logoBytes = await _loadLogoBytes();
      logoBytes = await _loadLogoBytes();
      print(logoBytes);
      final String textoFactura = generarTextoFacturaConDetalle(
        venta: venta,
        productos: productos,
        ivaPorcentaje: ivaPorcentaje,
        tipoCambio: tipoCambio,
      );

      final Map<String, dynamic> printPayload = {
        "text": textoFactura,
        "logo": logoBytes,
        "result": _selectedDeviceAddress,
      };

      final String? result = await platform.invokeMethod("printFactura", printPayload);

      _showSnackBar(context, 'Imprimiendo factura...');
      return true;
    } on PlatformException catch (e) {
      if (e.code == "NOT_CONNECTED") {
        if (_selectedDeviceAddress != null) {
          await connectToDevice(context, _selectedDeviceAddress!);
          // _showSnackBar(context,  'Reintentando imprimir...');
          notifyListeners();
          // imprimirFactura(context: context, venta: venta, productos: productos, ivaPorcentaje: ivaPorcentaje, tipoCambio: tipoCambio);
        } else {
          await showDeviceSelectionDialog(context);
        }
      }
      return false;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }
}