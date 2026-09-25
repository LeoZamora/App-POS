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


  String generarPiePaginaDevoDigital({int ancho = 31}) {
    const String texto = 'Impresiones DevoDigital';
    if (texto.length >= ancho) return texto.substring(0, ancho);
    final int espacios = (ancho - texto.length) ~/ 2;
    return ' ' * espacios + texto;
  }

// Ancho del ticket en caracteres (típico para impresoras térmicas de 58mm
// con fuente normal). Ajusta este número si tu impresora imprime más
// angosto o más ancho de lo que se ve bien.

  String generarTextoFacturaConDetalle({
    required VentaModel? venta,
    required List<Map<String, dynamic>> productos,
    bool isCopy = false,
    bool? showIva = false,
    double ivaValue = 0,
    double ivaPorcentaje = 15,
    double tipoCambio = 36.50,
    double pagaCon = 0.0,
    double totalVenta = 0.0,
    double cambio = 0.0,
    double descuento = 0.0,
    String formaPago = '',
  }) {
    const int _anchoTicket = 31;
    final buffer = StringBuffer();
    final String symbolCor = 'C${String.fromCharCode(36)}';

    String _centrar(String texto, [int ancho = _anchoTicket]) {
      if (texto.length >= ancho) return texto.substring(0, ancho);
      final int espacios = (ancho - texto.length) ~/ 2;
      return ' ' * espacios + texto;
    }

    String _truncar(String texto, int maxLen) {
      return texto.length <= maxLen ? texto : texto.substring(0, maxLen);
    }

    /// Arma una línea tipo "ETIQUETA        C$   123.45", alineando el valor
    /// a la derecha dentro del ancho del ticket, sin tener que calcular
    /// espacios a mano en cada llamada.
    String _linea(String etiqueta, String valor, [int ancho = _anchoTicket]) {
      final int espacios = ancho - etiqueta.length - valor.length;
      return etiqueta + ' ' * (espacios > 1 ? espacios : 1) + valor;
    }

    double subtotal = 0;
    for (var p in productos) {
      subtotal += p['cantidad'] * p['precioUnitario'];
    }

    final double ivaAplicado = (showIva ?? false) ? ivaValue : 0;
    final double total = (subtotal - descuento) + ivaAplicado;

    // --- ENCABEZADO ---
    buffer.writeln(_centrar("Migdalia's Market"));
    buffer.writeln(_centrar('Tel: +505 2263-2783'));
    buffer.writeln('');
    buffer.writeln('');
    buffer.writeln(_linea('Ticket No:', venta?.noVenta.toString().padLeft(5, '0') ?? '- - -'));
    buffer.writeln(_linea('Credito:', venta?.credito == true ? 'SI' : 'NO'));
    buffer.writeln(_linea('Cliente:', _truncar(venta?.cliente?.toString() ?? 'N/A', 20)));
    buffer.writeln(_linea('Fecha:', venta?.fechaRegistro?.substring(0, 10) ?? '- - -'));
    buffer.writeln('');
    buffer.writeln('Enviar a:');
    buffer.writeln(venta?.enviarA ?? "- - -");
    buffer.writeln('');
    buffer.writeln('Descripcion:');
    buffer.writeln(venta?.observaciones ?? "- - -");

    // --- DETALLE DE PRODUCTOS ---

    buffer.writeln('');
    buffer.writeln('PRODUCTOS');
    buffer.writeln('-' * _anchoTicket);

    for (var p in productos) {
      final cant = p['cantidad'].toString();
      final nombre = (p['nombre'] as String);
      final precio = (p['precioUnitario'] as num).toDouble();
      final total = (p['total'] as num).toDouble();

      buffer.writeln(nombre);
      buffer.writeln('$cant x $symbolCor${formattedNumber(precio)}');
      buffer.writeln('Desc: $symbolCor${p['descuento'] ?? 0.0}      $symbolCor${formattedNumber(total)}');
      buffer.writeln('');
    }

    // --- TOTALES ---
    buffer.writeln('');
    buffer.writeln('RESUMEN');
    buffer.writeln('-' * _anchoTicket);
    buffer.writeln(_linea('SUBTOTAL', '$symbolCor${formattedNumber(subtotal)}'));

    buffer.writeln(_linea('IVA ($ivaPorcentaje%)', '$symbolCor${formattedNumber(ivaAplicado)}'));

    if (descuento > 0) {
      buffer.writeln(_linea('DESCUENTO', '$symbolCor${formattedNumber(descuento)}'));
    }

    buffer.writeln(_linea('TOTAL', '$symbolCor${formattedNumber(totalVenta)}'));
    buffer.writeln('');

    // --- FORMA DE PAGO ---
    buffer.writeln('-' * _anchoTicket);
    buffer.writeln(_centrar(formaPago.isNotEmpty ? formaPago : ''));
    buffer.writeln('');

    final bool esEfectivo = formaPago.isEmpty || formaPago == 'Efectivo';
    if (esEfectivo) {
      buffer.writeln(_linea('PAGA CON', '$symbolCor${formattedNumber(pagaCon)}'));
      buffer.writeln(_linea('CAMBIO', '$symbolCor${formattedNumber(cambio)}'));
    }

    // --- PIE DE TICKET ---
    buffer.writeln('');
    buffer.writeln(_centrar('!Gracias por su compra!'));
    buffer.writeln(_centrar('Ante cualquier duda o'));
    buffer.writeln(_centrar('consulta, comunicarse a'));
    buffer.writeln(_centrar('+505 2263-2783'));
    buffer.writeln('');
    if (isCopy) {
      buffer.writeln(_centrar('COPIA'));
    }

    buffer.writeln('');
    buffer.writeln(generarPiePaginaDevoDigital());


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
    double totalVenta = 0.0,
    double tipoCambio = 36.50,
    double descuento = 0.0,
    double pagaCon = 0.0,
    double cambio = 0.0,
    String formaPago = ''
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
        totalVenta: totalVenta,
        ivaPorcentaje: ivaPorcentaje,
        tipoCambio: tipoCambio,
        pagaCon: pagaCon,
        cambio: cambio,
        formaPago: formaPago
      );

      final Map<String, dynamic> printPayload = {
        "text": textoFactura,
        "logo": logoBytes,
        "result": _selectedDeviceAddress,
      };

      final String? result = await platform.invokeMethod("printFactura", printPayload);

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

    buffer.writeln('');
    buffer.writeln(generarPiePaginaDevoDigital());


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

  String generarTextoArqueoCaja({
    required String nombreCaja,
    required String usuarioArqueo,
    required double totalVentas,
    required double totalEgresos,
    required double aperturaCon,
    required List<DesgloseEfectivo> desglose,
    bool isCopy = false,
  }) {
    final buffer = StringBuffer();
    final String symbolCor = 'C${String.fromCharCode(36)}';

    final double totalContado = desglose.fold<double>(0, (sum, item) => sum + item.subtotal);
    final double totalEsperado = (aperturaCon + totalVentas) - totalEgresos;
    final double diferencia = totalContado - totalEsperado;

    final String fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    buffer.writeln("        Migdalia's Market       ");
    buffer.writeln('       Tel: +505 8652-6458       ');
    buffer.writeln('');
    buffer.writeln('         ARQUEO DE CAJA          ');
    buffer.writeln('-------------------------------');
    buffer.writeln('Caja       :  $nombreCaja');
    buffer.writeln('Usuario    :  $usuarioArqueo');
    buffer.writeln('Fecha      :  $fecha');
    buffer.writeln('-------------------------------');
    buffer.writeln('');
    buffer.writeln('RESUMEN:');
    buffer.writeln('Apertura      :   $symbolCor${formattedNumber(aperturaCon).padLeft(10)}');
    buffer.writeln('Ventas      :   $symbolCor${formattedNumber(totalVentas).padLeft(10)}');
    buffer.writeln('Egresos     :   $symbolCor${formattedNumber(totalEgresos).padLeft(10)}');
    buffer.writeln('Esperado    :   $symbolCor${formattedNumber(totalEsperado).padLeft(10)}');
    buffer.writeln('-------------------------------');
    buffer.writeln('');
    buffer.writeln('DESGLOSE DE EFECTIVO:');
    buffer.writeln('-------------------------------');
    buffer.writeln('Denom.  | Cant | Subtotal');
    buffer.writeln('-------------------------------');

    for (var item in desglose) {
      if (item.cantidad <= 0) continue;

      final denom = '$symbolCor${item.valorDenominacion}'.padRight(8);
      final cant = item.cantidad.toString().padLeft(2).padRight(5);
      final subtotal = formattedNumber(item.subtotal).padLeft(9);

      buffer.writeln('$denom| $cant| $subtotal');
    }

    buffer.writeln('-------------------------------');
    buffer.writeln('TOTAL CONTADO:');
    buffer.writeln('        $symbolCor ${formattedNumber(totalContado)}');
    buffer.writeln('-------------------------------');
    buffer.writeln('');
    buffer.writeln('Firma: ________________________');
    buffer.writeln('');
    buffer.writeln('|            ${isCopy ? 'COPIA' : '     '}            |');
    buffer.writeln('');
    buffer.writeln(generarPiePaginaDevoDigital());

    return buffer.toString();
  }

  Future<bool> imprimirArqueoCaja({
    required BuildContext context,
    required String nombreCaja,
    required String usuarioArqueo,
    required double totalVentas,
    required double totalEgresos,
    required double aperturaCon,
    required List<DesgloseEfectivo> desglose,
    bool isCopy = false,
  }) async {
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

      final String textoArqueo = generarTextoArqueoCaja(
        nombreCaja: nombreCaja,
        usuarioArqueo: usuarioArqueo,
        totalVentas: totalVentas,
        totalEgresos: totalEgresos,
        desglose: desglose,
        isCopy: isCopy,
        aperturaCon: aperturaCon,
      );

      final Map<String, dynamic> printPayload = {
        "text": textoArqueo,
        "logo": logoBytes,
        "result": _selectedDeviceAddress,
      };

      final String? result = await platform.invokeMethod("printFactura", printPayload);

      ToastSnackBar.show(
        context,
        message: 'Imprimiendo arqueo de caja...',
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
