import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/widgets/alertReusable.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/dbModels/models_type.dart';

import '../widgets/overlayCircle.dart';

// Modelo simple para representar un renglón en nuestra lista
class DesgloseEfectivo {

  final int valorDenominacion;
  final int cantidad;

  DesgloseEfectivo({
    required this.valorDenominacion,
    required this.cantidad,
  });

  double get subtotal => (valorDenominacion * cantidad).toDouble();
}

class CajaScreen extends ConsumerStatefulWidget {
  final bool isCierre;

  const CajaScreen({
    super.key,
    this.isCierre = false,
  });

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen> {
  bool _isFormOpen = false;
  List<CajaModel> _cajasDisponibles = [];
  final _observacionesController = TextEditingController();
  ResumenTotalesModel? _resumen;

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
  }

  // Lista donde guardaremos los renglones agregados
  CajaModel? _cajaSeleccionada;
  int _idCaja = 0;
  int _idUsuarioApertura = 0;
  final List<DesgloseEfectivo> _listaDesglose = [];

  // Denominaciones disponibles
  final List<int> _denominaciones = [1000, 500, 200, 100, 50, 20, 10, 5, 1];
  int _denominacionSeleccionada = 1000;

  // Controlador para el campo de cantidad
  final TextEditingController _cantidadController = TextEditingController();

  // Calcula la suma de toda la lista
  double get _totalCaja {
    return _listaDesglose.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Agrega un nuevo renglón a la lista
  void _agregarRenglon() {
    final cantidadText = _cantidadController.text;
    if (cantidadText.isEmpty) return;

    final cantidad = int.tryParse(cantidadText);
    if (cantidad == null || cantidad <= 0) return;

    setState(() {
      // Si ya existe esa denominación en la lista, le sumamos la cantidad
      final indexExistente = _listaDesglose.indexWhere((item) => item.valorDenominacion == _denominacionSeleccionada);

      if (indexExistente >= 0) {
        final itemActual = _listaDesglose[indexExistente];
        _listaDesglose[indexExistente] = DesgloseEfectivo(
            valorDenominacion: _denominacionSeleccionada,
            cantidad: itemActual.cantidad + cantidad
        );
      } else {
        // Si no existe, agregamos el nuevo renglón
        _listaDesglose.add(DesgloseEfectivo(
            valorDenominacion: _denominacionSeleccionada,
            cantidad: cantidad
        ));
      }

      // Limpiamos el input para el siguiente ingreso y ordenamos la lista de mayor a menor
      _cantidadController.clear();
      _listaDesglose.sort((a, b) => b.valorDenominacion.compareTo(a.valorDenominacion));
    });
  }

  // Elimina un renglón
  void _eliminarRenglon(int index) {
    setState(() {
      _listaDesglose.removeAt(index);
    });
  }

  Future<void> _cargarDatos(int idCaja) async {
    try {

      final ResumenTotalesModel? resumen = await getResumenCajaTotales(idCaja);

      if (!mounted) return;
      setState(() {
        _resumen = resumen;
      });

    } catch (e) {
      if (!mounted) return;
      ToastSnackBar.show(
          context,
          message: 'Error al cargar los datos',
          type: ToastType.warning
      );
    }
  }

   Future<void> _enviarApertura(payload) async {
    if(!widget.isCierre) {
      if (_listaDesglose.isEmpty || _cajaSeleccionada == null || _idUsuarioApertura == 0) {
        print('$_listaDesglose - $_idCaja - $_idUsuarioApertura - $_cajaSeleccionada' );
        return ToastSnackBar.show(context,
          message: 'Debe agregar al menos una denominación y elegir una caja',
          type: ToastType.warning
        );
      }
    }

    String msgLoader = widget.isCierre ? 'Arqueando caja' : 'Abriendo caja';
    String msgSucces = widget.isCierre ? 'Arqueo de caja exitoso' : 'Apertura de caja exitosa';
    String goRoute = widget.isCierre ? '/caja/false' : '/';

    try {
      final Map<String, dynamic> data = {
        "idCaja": _cajaSeleccionada?.idCaja ?? 0,
        "idUsuarioApertura": _idUsuarioApertura,
        "observaciones": _observacionesController.text,
        "desgloceDetalle": _listaDesglose.map((item) => {
          "valorDenominacion": item.valorDenominacion,
          "cantidad": item.cantidad
        }).toList()
      };

      final Map<String, dynamic> arqueoCaja = {
        "idAperturaCaja": ref.read(authProvider).idAperturaCaja,
        "montoArqueoRetiros": _resumen?.totalRetiros ?? 0,
        "observaciones": _observacionesController.text,
        "desgloceDetalle":  _listaDesglose.map((item) => {
          "valorDenominacion": item.valorDenominacion,
          "cantidad": item.cantidad
        }).toList()
      };


      LoadingOverlay.show(context, message: '$msgLoader ${_cajaSeleccionada?.nombre ?? ''}...');

      if(!widget.isCierre) {
        await postAperturaCaja(data);
      } else {
        await arquearCaja(arqueoCaja);
      }

      LoadingOverlay.hide();

      ToastSnackBar.show(context,
          message: msgSucces,
          type: ToastType.success
      );

      if(widget.isCierre) {
        await ref.read(authProvider.notifier).checkAuthStatus();
      } else {
        await ref.read(authProvider.notifier).openCaja(_cajaSeleccionada!.idCaja);
      }

    } on DioException catch (e) {
      LoadingOverlay.hide();
      String mensajeError = widget.isCierre ? 'Arqueo de caja fallido' : 'Apertura de caja fallida';

      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;

        if (data is Map<String, dynamic>) {
          mensajeError = data['ex'] ?? data['msg'] ?? mensajeError;
        }
      }

      if (!mounted) return;
      ToastSnackBar.show(
        context,
        message: mensajeError,
        type: ToastType.error,
      );
    } catch (e, stackTrace) {
      print('ERROR: $e');
      print(stackTrace);

      LoadingOverlay.hide();
      if (!mounted) return;
      ToastSnackBar.show(
        context,
        message: 'Ocurrió un error inesperado',
        type: ToastType.error,
      );
    }

    final Map<String, int> desgloseAEnviar = {
      for (var item in _listaDesglose) item.valorDenominacion.toString(): item.cantidad
    };

  }

  void _confirmarOpenCaja(BuildContext context, payload) async {
    String title = widget.isCierre ? 'Arquear Caja' : 'Abrir Caja';
    String msg = widget.isCierre ? '¿Estás seguro de que deseas cerrar caja?' : '¿Estás seguro de que deseas abrir caja?';

    final openCaja = await AlertReusable.show(
        context,
        title: title,
        message: msg,
        yesText: 'SI',
        noText: 'NO',
        icon: Icons.lock_open_rounded,
        primaryColor: Colors.indigo
    );

    if(openCaja) {
      await _enviarApertura(payload);
    } else {
      context.pop();
    }
  }

  Future<void> _getCajasDisponibles(idUsuario) async {
    try {
      final cajas = await getCajas(idUsuario);

      if (!mounted)  return;

      setState(() {
        _cajasDisponibles = cajas;
      });
    } catch (e) {
      print('Error al obtener las cajas disponibles: $e');
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final TokenPayload? userPayload = ref.watch(authProvider).userPayload;

      if (userPayload == null) return;

      if (widget.isCierre) {
        await _cargarDatos(ref.read(authProvider).idCajaOpen);
      } else {
         await _getCajasDisponibles(userPayload.idusuario);
        _idUsuarioApertura = int.parse(userPayload.idusuario);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final authState = ref.watch(authProvider);
    String title = widget.isCierre ? 'Arqueo de Caja' : 'Apertura de Caja';

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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 0;
        },
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        shadowColor: Colors.grey[200],
        titleSpacing: 16,
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
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            // padding: !widget.isCierre ? const EdgeInsets.all(20.0) : const EdgeInsets.all(0.0),
            padding: const EdgeInsets.all(0.0),
            child: Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Theme(
                      data: Theme.of(context).copyWith(inputDecorationTheme: estiloInput),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- ENCABEZADO ---
                          if(!widget.isCierre) CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.indigo.shade50,
                            child: const Icon(Icons.point_of_sale_rounded, size: 32, color: Colors.indigo),
                          ),
                          if(!widget.isCierre) const SizedBox(height: 16),
                          Text(
                            widget.isCierre ? 'Arqueo de Caja' : 'Apertura de Turno',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isFormOpen
                                ? 'Registra el fondo inicial de la caja'
                                : 'Selecciona una opción para continuar',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // BOTÓN INICIAL DE APERTURA
                          if (!_isFormOpen && !widget.isCierre)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isFormOpen = true;
                                      });
                                    },
                                    icon: const Icon(Icons.lock_open_rounded),
                                    label: Text(
                                      widget.isCierre ? 'Arquear Caja' : 'Comenzar Apertura',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1a237e),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                if (!widget.isCierre) const SizedBox(height: 10), SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await ref.read(authProvider.notifier).logout();
                                      GoRouter.of(context).go('/login');
                                    },
                                    icon: const Icon(Icons.logout_rounded, size: 20),
                                    label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 15)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade600,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                )
                              ],
                            )

                          // FORMULARIO
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!widget.isCierre) DropdownFlutter<CajaModel>(
                                  initialItem: _cajaSeleccionada,
                                  hintText: 'Seleccione una caja',
                                  decoration: const CustomDropdownDecoration(
                                    expandedFillColor: Colors.white,
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                    headerStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    prefixIcon: Icon(Icons.storefront_outlined, color: Colors.grey),
                                    closedBorder: Border(
                                      top: BorderSide(color: Colors.grey),
                                      bottom: BorderSide(color: Colors.grey),
                                      left: BorderSide(color: Colors.grey),
                                      right: BorderSide(color: Colors.grey),
                                    ),
                                    closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                                    expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.indigo),
                                  ),
                                  items: _cajasDisponibles.map<CajaModel>((caja) => caja).toList(),
                                  headerBuilder: (context, selectedItem, enabled) {
                                    return Text(
                                      '${selectedItem.nombre} - ${selectedItem.bodega}',
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                  listItemBuilder: (context, item, isSelected, onItemSelected) {
                                    return Text('${item.nombre} - ${item.bodega}');
                                  },
                                  validateOnChange: true,
                                  validator: (value) => value == null ? 'Seleccione un tipo' : null,
                                  onChanged: (value) async {
                                    if (value != null) {
                                      setState(() {
                                        _cajaSeleccionada = value;
                                        _idCaja = value.idCaja;
                                      });
                                    }
                                  },
                                ),

                                !widget.isCierre ? const SizedBox(height: 28) : const SizedBox(height: 0),

                                if(widget.isCierre) _buildResumenCard(),

                                const SizedBox(height: 10),

                                // --- ZONA DE CAPTURA DE DENOMINACIONES ---
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 18, color: Colors.black87),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Desglose de efectivo',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Denominación',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 8),

                                      // Selector de denominación en chips horizontales:
                                      // evita el overflow que daba el DropdownButtonFormField
                                      // al competir por ancho con el resto de la fila.
                                      SizedBox(
                                        height: 40,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _denominaciones.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            final denom = _denominaciones[index];
                                            final bool isSelected = _denominacionSeleccionada == denom;

                                            return ChoiceChip(
                                              label: Text('C\$ $denom'),
                                              selected: isSelected,
                                              onSelected: (_) {
                                                setState(() {
                                                  _denominacionSeleccionada = denom;
                                                });
                                              },
                                              selectedColor: const Color(0xff1a237e),
                                              backgroundColor: Colors.white,
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              side: BorderSide(
                                                color: isSelected ? const Color(0xff1a237e) : Colors.grey.shade300,
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _cantidadController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Cantidad',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                              onFieldSubmitted: (_) => _agregarRenglon(),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            height: 48,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.add_rounded, color: Colors.indigo),
                                              onPressed: _agregarRenglon,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // --- LISTA DINÁMICA DE DESGLOSE ---
                                if (_listaDesglose.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.list_alt_rounded, size: 18, color: Colors.black87),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Desglose ingresado',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 15),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_listaDesglose.length} renglón(es)',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _listaDesglose.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = _listaDesglose[index];

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.shade200),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Badge de la denominación (grande, legible)
                                            Container(
                                              width: 58,
                                              height: 58,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'C\$',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                                  ),
                                                  Text(
                                                    '${item.valorDenominacion}',
                                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            // Cantidad + precio unitario
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${item.cantidad} pieza(s)',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'C\$ ${item.valorDenominacion} c/u',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Subtotal + eliminar
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'C\$ ${item.subtotal.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.indigo),
                                                ),
                                                const SizedBox(height: 6),
                                                InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () => _eliminarRenglon(index),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade300),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 16),

                                TextField(
                                  controller: _observacionesController,
                                  autofocus: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Observaciones',
                                    labelStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: Icon(Icons.comment_outlined, color: Colors.grey),
                                    isDense: false,
                                  ),
                                  style: TextStyle(color: Colors.grey[700]),
                                  minLines: 4,
                                  maxLines: 4,
                                ),

                                const SizedBox(height: 20),
                                Divider(height: 1, color: Colors.grey.shade200),
                                const SizedBox(height: 20),

                                // --- TOTAL EN CAJA ---
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total en Caja',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                      ),
                                      Text(
                                        'C\$ ${formattedNumber(_totalCaja)}',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () => _confirmarOpenCaja(context, authState.userPayload),
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xff1a237e),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      widget.isCierre ? 'Arquear Caja' : 'Abrir Caja',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if(!widget.isCierre) SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isFormOpen = false;
                                        _listaDesglose.clear();
                                        _cantidadController.clear();
                                        _observacionesController.clear();


                                        print('${widget.isCierre}, $_isFormOpen');
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade600,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('Cancelar', style: TextStyle(fontSize: 15)),
                                  ),
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard() {

    final double disponibble = (_resumen?.totalEnCaja ?? 0);
    final double totalRetiros = _resumen?.totalRetiros ?? 0;
    final total = (_resumen?.totalEnCaja ?? 0) + (_resumen?.totalRetiros ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _resumenStat(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.green.shade600,
                  iconBg: Colors.green.shade50,
                  label: 'Disponible',
                  value: disponibble,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resumenStat(
                  icon: Icons.arrow_circle_up_outlined,
                  iconColor: Colors.red.shade600,
                  iconBg: Colors.red.shade50,
                  label: 'Retirado',
                  value: totalRetiros,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Capital Total', style: TextStyle(fontSize: 15, color: Colors.black87)),
              const Spacer(),
              Text(
                'C\$ ${formattedNumber(total)}',
                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenStat({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            'C\$ ${formattedNumber(value)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

