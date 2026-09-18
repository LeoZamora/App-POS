import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:inversiones_ar/helpers/formatters.dart';
import 'package:inversiones_ar/widgets/alertReusable.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:inversiones_ar/requestHttp/requestHttp.dart';

import '../features/providers/authProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';


String formattedNumber(num value) {
  final formatter = NumberFormat('#,##0.00', 'es_NI');
  return formatter.format(value);
}

class EgresosCapitalScreen extends ConsumerStatefulWidget {
  const EgresosCapitalScreen({super.key});

  @override
  ConsumerState<EgresosCapitalScreen> createState() => _EgresosCapitalScreenState();
}

class _EgresosCapitalScreenState extends ConsumerState<EgresosCapitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final connectionChecker = InternetConnectionChecker.instance;
  bool isConnected = false;
  late StreamSubscription<InternetConnectionStatus> _connectionStatus;

  bool _isLoading = true;
  ResumenTotalesModel? _resumen;
  List<RetiroEfectivoModel> _movimientos = [];
  List<GenericModelCombobox> _conceptos = [];
  GenericModelCombobox? _conceptoSeleccionado;

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _connectionStatus = connectionChecker.onStatusChange.listen((status) {
      if (!mounted) return;
      setState(() {
        isConnected = status == InternetConnectionStatus.connected;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _cargarDatos(ref.read(authProvider).idCajaOpen);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectionStatus.cancel();
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos(int idCaja) async {
    try {

      final ResumenTotalesModel? resumen = await getResumenCajaTotales(idCaja);
      final List<GenericModelCombobox> conceptos = await getConceptosCombobox();
      final List<RetiroEfectivoModel> movimientos = await getRetirosEfectivo(idCaja);

      if (!mounted) return;
      setState(() {
        // _resumen = results[0] as ResumenTotalesModel;
        _movimientos = movimientos;
        _resumen = resumen;
        _conceptos = conceptos;
        _isLoading = false;
      });

      setState(() {
        _conceptoSeleccionado = null;
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

  Future<void> _registrarRetiro(int idCaja) async {
    if (!_formKey.currentState!.validate()) return;

    final double monto = double.tryParse(_montoController.text) ?? 0;
    final double disponible = (_resumen?.efectivoApertura ?? 0) - (_resumen?.totalRetiros ?? 0);

    if (monto > disponible) {
      ToastSnackBar.show(
          context,
          message: 'El monto (C\$ ${formattedNumber(monto)}) supera el capital disponible '
              '(C\$ ${formattedNumber(disponible)})',
          type: ToastType.warning
      );
      return;
    }

    final Map<String, dynamic> data = {
      'idConcepto': _conceptoSeleccionado?.id,
      'monto': monto,
      'observaciones': _conceptoController.text.trim(),
    };

    try {
      Navigator.of(context).pop();
      LoadingOverlay.show(context);

      final response = await postRetiroEfectivo(data);
      LoadingOverlay.hide();

      if (!mounted) return;

      _montoController.clear();
      _conceptoController.clear();


      ToastSnackBar.show(
          context,
          message: '${response['msg']}',
          type: ToastType.success
      );

      await _cargarDatos(idCaja);
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.hide();
      ToastSnackBar.show(
          context,
          message: 'Error al registrar el retiro',
          type: ToastType.warning
      );
    }
  }

  void _confirmarMarcarRetiro(BuildContext context, int idCaja) async {
    final openCaja = await AlertReusable.show(
        context,
        title: 'Registrar retiro',
        message: '¿Está seguro de registrar el retiro?',
        yesText: 'SI',
        noText: 'NO',
        icon: Icons.check_circle_outline_sharp,
        primaryColor: Colors.indigo
    );

    if(openCaja) {
      await _registrarRetiro(idCaja);
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }

  void _abrirDialogoNuevoRetiro(int idCaja) {
    _montoController.clear();
    _conceptoController.clear();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Nuevo Retiro de Capital',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.indigo, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Disponible: C\$ ${formattedNumber(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownFlutter<GenericModelCombobox>.search(
                    enabled: true,
                    key: ValueKey('cat_${_conceptos.length}'),
                    initialItem: _conceptoSeleccionado,
                    hintText: 'Seleccione un concepto',
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
                    items: _conceptos,
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

                      if(value != null) {
                        if (!mounted) return;

                        setState(() {
                          _conceptoSeleccionado = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
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
                  TextFormField(
                    controller: _conceptoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async => _confirmarMarcarRetiro(context, idCaja),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Guardar', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

  Widget _buildMovimientoItem(RetiroEfectivoModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.red.shade50,
            child: Icon(Icons.arrow_upward_rounded, color: Colors.red.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.conceptoNombre ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatedDate(item.fechaRegistro)} • ${item.usuarioRegistro}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '- C\$ ${formattedNumber(item.monto as num)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
        shadowColor: Colors.grey[200],
        centerTitle: true,
        title: const Text(
          'EGRESOS DE CAPITAL',
          style: TextStyle(fontSize: 18.0, letterSpacing: 0.5),
        ),
        actions: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(
        child: LoadingAnimationWidget.threeArchedCircle(color: Colors.indigo, size: 40),
      )
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            color: Colors.indigo,
            onRefresh: () async => _cargarDatos(ref.watch(authProvider).idCajaOpen),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumenCard(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        'Movimientos',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _movimientos.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'NO HAY RETIROS REGISTRADOS',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _movimientos.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) => _buildMovimientoItem(_movimientos[index]),
                  ),
                ],
              ),
            ),
          )
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoNuevoRetiro(ref.watch(authProvider).idCajaOpen),
        backgroundColor: const Color(0xff1a237e),
        icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
        label: const Text(
          'Nuevo Retiro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}