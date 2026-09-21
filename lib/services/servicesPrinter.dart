import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';

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

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/devo/32px.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      print("Error cargando el logo: $e");
      return null;
    }
  }

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  String generarTextoFacturaConDetalle({
    required VentaModel? venta,
    required List<Map<String, dynamic>> productos,
    bool isCopy = false,
    bool? showIva = false,
    ivaValue = 0,
    double ivaPorcentaje = 15,
    double tipoCambio = 36.50,
    double pagaCon = 0.0,
    double cambio = 0.0,
    double descuento = 0.0
  }) {
    final buffer = StringBuffer();

    double subtotal = 0;
    for (var p in productos) {
      subtotal += p['cantidad'] * p['precioUnitario'];
    }
    double total = (subtotal - descuento) + ivaValue;

    buffer.writeln("        Migdalia's Market       ".toString());
    buffer.writeln('       Tel: +505 2263-2783       '.toString());
    buffer.writeln('Ticket No:            ${venta?.noVenta.toString().padLeft(5, '0')}');
    buffer.writeln('Credito:                      ${venta?.credito == true ? 'SI' : 'NO'}');
    buffer.writeln('Cliente : ${venta?.cliente.toString().padLeft(20)}');
    buffer.writeln('Fecha:                ${venta?.fechaRegistro?.substring(0, 10)}');
    buffer.writeln('');
    buffer.writeln('Enviar a:');
    buffer.writeln(venta?.enviarA ?? "- - -");
    buffer.writeln('Descripcion:');
    buffer.writeln(venta?.observaciones ?? "- - -");
    buffer.writeln('');
    buffer.writeln('-------------------------------');
    buffer.writeln('Cant   |  Producto  |  Total');
    buffer.writeln('-------------------------------');
    for (var p in productos) {
      final cant = p['cantidad'].toString().padLeft(1).padRight(2);
      final nombre = (p['nombre'] as String).padRight(8).substring(0, 8);
      final totalLinea = (p['cantidad'] * p['precioUnitario'])
          .toStringAsFixed(2)
          .padLeft(6)
          .substring(0, 6);

      buffer.writeln('$cant | $nombre  | C\$$totalLinea');
    }

    final String symbolCor = 'C${String.fromCharCode(36)}';
    final String symbolDolar = String.fromCharCode(36);

    buffer.writeln('');
    buffer.writeln('SUBTOTAL    :        ${symbolCor + formattedNumber(subtotal).padLeft(8)}');
    buffer.writeln('IVA ($ivaPorcentaje%) :        ${symbolCor + ivaValue.toStringAsFixed(2).padLeft(8)}');
    buffer.writeln('DESCUENTO    :        ${symbolCor + formattedNumber(descuento).padLeft(8)}');
    buffer.writeln('TOTAL       :        ${symbolCor + formattedNumber(total).padLeft(8)}');
    // buffer.writeln('TOTAL       :        ${symbolDolar + formattedNumber((total / tipoCambio)).padLeft(9)}');
    // buffer.writeln('Tipo Cambio :        ${symbolCor + tipoCambio.toStringAsFixed(2).padLeft(8)}');

    buffer.writeln('');

    buffer.writeln('-------------------------------');
    buffer.writeln('PAGA CON    :        ${symbolCor + formattedNumber(pagaCon).padLeft(8)}');
    buffer.writeln('CAMBIO      :        ${symbolCor + formattedNumber(cambio).padLeft(8)}');

    buffer.writeln('');
    buffer.writeln('|   !Gracias por su compra!   |');
    buffer.writeln('|   Ante cualquier duda  o    |\n|   consulta, comunicarse a   |\n|       +505 2263-2783        |');
    buffer.writeln('|                             |');
    buffer.writeln('|            ${isCopy ? 'COPIA' : '     '}            |');

    return buffer.toString();
  }

  Future<bool> checkBluetoothPermissions({BuildContext? context}) async {
    try {
      final bool? granted = await platform.invokeMethod("checkBluetoothPermissions");
      if (granted == false && context != null) {
        ToastSnackBar.show(
          context,
          message: 'Los permisos de Bluetooth son necesarios. \nPor favor, concédelos en los ajustes de la app.',
          type: ToastType.warning,
        );
      }
      return granted ?? false;
    } on PlatformException catch (e) {
      print("Error al verificar permisos de Bluetooth: ${e.message}");
      if (context != null) {
        ToastSnackBar.show(
          context,
          message: 'Error al verificar permisos de Bluetooth: ${e.message}',
          type: ToastType.error,
        );
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
        if (context != null) {
          ToastSnackBar.show(
            context,
            message: 'Permisos de Bluetooth concedidos.',
            type: ToastType.success,
          );
        }
      }
      return ultimatelyGranted;
    } on PlatformException catch (e) {
      print("Error al solicitar permisos de Bluetooth: ${e.message}");
      if (context != null) {
        ToastSnackBar.show(
          context,
          message: 'Error al solicitar permisos de Bluetooth: ${e.message}',
          type: ToastType.error,
        );
      }
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
      ToastSnackBar.show(
        context,
        message: 'Error al obtener dispositivos vinculados: ${e.message}',
        type: ToastType.error,
      );
      _pairedDevices = [];
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BuildContext context, String address) async { // Pasa BuildContext
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      _connectionStatus = "Conectando a ${address}...";
      ToastSnackBar.show(
        context,
        message: 'Conectando a ${address}...',
        type: ToastType.info,
      );

      final String? result = await platform.invokeMethod("connectToDevice", {"address": address});
      _connectionStatus = result ?? "Conectado";
      _selectedDeviceAddress = address;
      ToastSnackBar.show(
        context,
        message: 'Conectado a ${address}',
        type: ToastType.success,
      );
      notifyListeners();
    } on PlatformException catch (e) {
      _connectionStatus = "Error de conexión: ${e.message}";
      ToastSnackBar.show(
        context,
        message: 'Error de conexión: ${e.message}',
        type: ToastType.error,
      );
      notifyListeners();
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
      ToastSnackBar.show(
        context,
        message: 'Desconectado',
        type: ToastType.success,
      );
    } catch (e) {
      ToastSnackBar.show(
        context,
        message: 'Error al desconectar: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> showDeviceSelectionDialog(BuildContext context) async {
    await getPairedDevices(context);
    if (!context.mounted) return;

    // Antes: el onTap conectaba y cerraba el diálogo sin esperar la
    // conexión, así que este Future se resolvía antes de que
    // _selectedDeviceAddress realmente se actualizara. Ahora: el diálogo
    // solo devuelve la dirección elegida (Navigator.pop(address)), y
    // conectamos DESPUÉS, aquí abajo, con await.
    final String? selectedAddress = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text("Selecciona una impresora"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _pairedDevices.isEmpty
                ? const Text(
                "No hay impresoras vinculadas. \nAsegúrate de vincular tu impresora en los ajustes de Bluetooth del dispositivo.")
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _pairedDevices.length,
              itemBuilder: (context, index) {
                final device = _pairedDevices[index];
                return ListTile(
                  title: Text(device["name"] ?? "Dispositivo desconocido"),
                  textColor: selectedDeviceAddress == device["address"]
                      ? Colors.indigo
                      : Colors.black,
                  subtitle: Text(device["address"] ?? ""),
                  dense: true,
                  onTap: () {
                    // Solo devolvemos la dirección elegida; ya NO
                    // conectamos aquí dentro.
                    Navigator.of(dialogContext).pop(device["address"]);
                  },
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      disconnectDevice(context);
                    },
                    child: Icon(
                      Icons.print_disabled_outlined,
                      color: selectedDeviceAddress == device['address']
                          ? Colors.red
                          : Colors.transparent,
                      size: 20.0,
                    ),
                  ),
                  trailing: Icon(
                    Icons.check_circle_outline,
                    color: selectedDeviceAddress == device['address']
                        ? Colors.indigo
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // cancelar -> null
              },
              child: const Text("Cancelar"),
            )
          ],
        );
      },
    );

    // Ahora sí: showDeviceSelectionDialog() no se considera "terminado"
    // hasta que la conexión real haya sucedido (o fallado).
    if (selectedAddress != null && context.mounted) {
      await connectToDevice(context, selectedAddress);
    }
  }


  Future<bool> imprimirFactura({
    required BuildContext context,
    required VentaModel? venta,
    required List<Map<String, dynamic>> productos,
    bool isCopy = false,
    bool? showIva = false,
    double ivaPorcentaje = 15,
    double ivaValue = 0,
    double tipoCambio = 36.50,
    double descuento = 0.0,
    double pagaCon = 0.0,
    double cambio = 0.0,
  }) async {
    if (_selectedDeviceAddress == null) {
      ToastSnackBar.show(
        context,
        message: 'Por favor, selecciona y conecta una impresora primero.',
        type: ToastType.warning,
      );
      await showDeviceSelectionDialog(context);
      if(_selectedDeviceAddress == null) return false;
    }

    if (_isPrinting) return false;
    _isPrinting = true;
    notifyListeners();

    try {
      // final showIva = await getParametroFirebase();
      Uint8List? logoBytes = await _loadLogoBytes();
      logoBytes = await _loadLogoBytes();
      final String textoFactura = generarTextoFacturaConDetalle(
        venta: venta,
        productos: productos,
        isCopy: isCopy,
        showIva: showIva,
        ivaValue: ivaValue,
        descuento: descuento,
        ivaPorcentaje: ivaPorcentaje,
        tipoCambio: tipoCambio,
        pagaCon: pagaCon,
        cambio: cambio,

      );

      final Map<String, dynamic> printPayload = {
        "text": textoFactura,
        "logo": logoBytes,
        "result": _selectedDeviceAddress,
      };

      final String? result = await platform.invokeMethod("printFactura", printPayload);

      ToastSnackBar.show(
        context,
        message: 'Imprimiendo ticket...',
        type: ToastType.success,
        duration: const Duration(seconds: 3),
      );
      return true;
    } on PlatformException catch (e) {
      if (e.code == "NOT_CONNECTED") {
        if (_selectedDeviceAddress != null) {
          await connectToDevice(context, _selectedDeviceAddress!);
          notifyListeners();
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



//   IMPRESION DE RETIROS DE CAJA
  String generarTextoRetiroCaja({
    required RetiroEfectivoModel retiro,
    bool isCopy = false,
  }) {
    final buffer = StringBuffer();

    final String symbolCor = 'C${String.fromCharCode(36)}';

    final double monto = (retiro.monto as num?)?.toDouble() ?? 0;

    final String fechaCompleta = retiro.fechaRegistro?.toString() ?? '';
    final String fecha = fechaCompleta.length >= 10 ? fechaCompleta.substring(0, 10) : '- - -';
    final String hora = fechaCompleta.length >= 16 ? fechaCompleta.substring(11, 16) : '';

    final String observaciones = (retiro.observaciones)?.trim() ?? '';
    final String noRetiro = (retiro.idRetiroCaja ?? '').toString().padLeft(5, '0');

    buffer.writeln("        Migdalia's Market       ");
    buffer.writeln('       Tel: +505 2263-2783       ');
    buffer.writeln('');
    buffer.writeln('     COMPROBANTE DE RETIRO       ');
    buffer.writeln('-------------------------------');
    buffer.writeln('No. Retiro :          $noRetiro');
    buffer.writeln('Apertura   :  ${retiro.aperturaCodigo ?? '- - -'}');
    buffer.writeln('Concepto   :  ${retiro.conceptoNombre ?? '- - -'}');
    buffer.writeln('Fecha      :  $fecha  $hora');
    buffer.writeln('Usuario    :  ${retiro.usuarioRegistro ?? '- - -'}');
    buffer.writeln('-------------------------------');
    buffer.writeln('');
    buffer.writeln('Observaciones:');
    buffer.writeln(observaciones.isNotEmpty ? observaciones : '- - -');
    buffer.writeln('');
    buffer.writeln('-------------------------------');
    buffer.writeln('MONTO RETIRADO:');
    buffer.writeln('        $symbolCor ${formattedNumber(monto)}');
    buffer.writeln('');
    buffer.writeln('Firma: ________________________');
    buffer.writeln('');
    buffer.writeln('|            ${isCopy ? 'COPIA' : '     '}            |');

    return buffer.toString();
  }


  Future<bool> imprimirRetiroCaja({
    required BuildContext context,
    required RetiroEfectivoModel retiro,
    bool isCopy = false,
  }) async {
    print('SELECTED DEVICE ADDRESS: $_selectedDeviceAddress');
    if (_selectedDeviceAddress == null) {
      ToastSnackBar.show(
        context,
        message: 'Por favor, selecciona y conecta una impresora primero.',
        type: ToastType.warning,
      );
      await showDeviceSelectionDialog(context);
      if (_selectedDeviceAddress == null) return false;
    }

    if (_isPrinting) return false;
    _isPrinting = true;
    notifyListeners();

    try {
      Uint8List? logoBytes = await _loadLogoBytes();

      final String textoRetiro = generarTextoRetiroCaja(
        retiro: retiro,
        isCopy: isCopy,
      );

      final Map<String, dynamic> printPayload = {
        "text": textoRetiro,
        "logo": logoBytes,
        "result": _selectedDeviceAddress,
      };

      final String? result = await platform.invokeMethod("printFactura", printPayload);

      ToastSnackBar.show(
        context,
        message: 'Imprimiendo comprobante de retiro...',
        type: ToastType.success,
        duration: const Duration(seconds: 3),
      );
      return true;
    } on PlatformException catch (e) {
      if (e.code == "NOT_CONNECTED") {
        if (_selectedDeviceAddress != null) {
          await connectToDevice(context, _selectedDeviceAddress!);
          notifyListeners();
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

final printerProvider = ChangeNotifierProvider((ref) {
  return  PrinterService();
});
