import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/widgets/alertReusable.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:inversiones_ar/helpers/formatters.dart';

class PedidoById extends ConsumerStatefulWidget {
  final int idPedido;

  const PedidoById({
    super.key,
    required this.idPedido
  });

  @override
  ConsumerState<PedidoById> createState() => _PedidoByIdState();
}

class _PedidoByIdState extends ConsumerState<PedidoById> {
  bool _isLoading = true;
  PedidoModelComplete? _pedido;
  String? _errorMessage;

  bool disableBtn(PedidoModelComplete? pedido) {
    return pedido?.estado?.toLowerCase() != 'entregado' && pedido?.estado?.toLowerCase() != 'entrega parcial';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _cargarPedido();
    });
  }

  Future<void> marcarPedidoEntregado() async {
    if (!mounted) return;

    if (_pedido?.detallePedido?.length == 0) {
      ToastSnackBar.show(
        context,
        type: ToastType.warning,
        message: 'Debe tener al menos un producto para entregar',
      );

      return;
    }

    late List<Map<String, dynamic>> productosConnected = [];

    setState(() {
      productosConnected.clear();

      for (var item in _pedido!.detallePedido!) {
        if (item.idProducto != null ) {
          productosConnected.add({
            "idProducto": item.idProducto,
            "cantidad": item.cantidad,
            "observaciones": "Sin detalles"
          });
        }
      }
    });


    Map<String, dynamic> body = {
      "idPedido": widget.idPedido,
      "detalleEntregado": productosConnected
    };

    try {

      LoadingOverlay.show(context, message: 'Marcando como entregado...');
      final result = await putPedidosEntrega(body, widget.idPedido);
      LoadingOverlay.hide();


      if(result?['code'] != 400 && result?['code'] != 404 && result?['code'] != 400.1) {
        ToastSnackBar.show(
          context,
          type: ToastType.success,
          message: 'Pedido marcado como entregado ',
        );

        Navigator.pop(context);
      } else {
        LoadingOverlay.hide();
        ToastSnackBar.show(
          context,
          type: ToastType.error,
          message: result?['msg'] ?? 'Error al registrar la venta',
        );
        return;
      }
    } catch (e){
      LoadingOverlay.hide();

      ToastSnackBar.show(
        context,
        type: ToastType.error,
        message: 'Error al registrar la venta: $e',
      );
    }
  }

  void _confirmarMarcarPedido(BuildContext context, payload) async {
    final valid = await AlertReusable.show(
        context,
        title: 'Marcar pedido',
        message: '¿Estás seguro de que deseas entregar este pedido?',
        yesText: 'SI',
        noText: 'NO',
        icon: Icons.check_circle_outline_sharp,
        primaryColor: Colors.indigo
    );

    if(valid) {
      await marcarPedidoEntregado();
    } else {
      Navigator.pop(context);
    }
  }

  void eliminarProducto(int index) {
    setState(() {
      _pedido?.detallePedido?.removeAt(index);
    });
  }

  void showProducto(BuildContext context, DetallePedidoModel item) {
    if(!mounted) return;

    if(item.idProducto != null) {
      final TextEditingController cantidadController =
      TextEditingController(
        text: item.cantidad.toString(),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Editar producto'),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // CÓDIGO
                Text(
                  'Código: ${item.codigoProducto ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // PRODUCTO
                Text(
                  'Producto: ${item.producto ?? ''}',
                ),

                const SizedBox(height: 20),

                // CANTIDAD
                TextField(
                  controller: cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
                  ),
                ),
              ],
            ),

            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final nuevaCantidad = double.tryParse(
                    cantidadController.text,
                  );

                  if (nuevaCantidad == null || nuevaCantidad <= 0) {
                    return;
                  }

                  final PedidoModelComplete pedidoLocal = await getPedidoById(widget.idPedido);

                  final DetallePedidoModel? itemLocal = pedidoLocal.detallePedido?.firstWhere(
                        (element) => element.codigoProducto == item.codigoProducto
                  );

                  if (nuevaCantidad > (itemLocal?.cantidad as double)) {
                    ToastSnackBar.show(
                      context,
                      type: ToastType.warning,
                      message: 'La cantidad ingresada es mayor a la cantidad disponible',
                    );
                    return;
                  }

                  setState(() {
                    final DetallePedidoModel updatedItem = _pedido!.detallePedido!.firstWhere(
                          (element) => element.codigoProducto == item.codigoProducto,
                    );

                    updatedItem.cantidad = nuevaCantidad;

                    _pedido!.totalAfecha = _pedido!.detallePedido!.fold(
                      0.0,
                          (previousValue, element) => previousValue! + (element.cantidad ?? 0) * (element.precioUnitarioAfecha ?? 0),
                    );
                  });

                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _cargarPedido() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      LoadingOverlay.show(context, message: 'Cargando datos...');
      final pedidoObtenido = await getPedidoById(widget.idPedido);
      LoadingOverlay.hide();

      if (mounted) {
        setState(() {
          _pedido = pedidoObtenido;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoadingOverlay.hide();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF172033),
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pedido?.noPedido != null
                  ? 'Pedido ${_pedido!.noPedido}'
                  : 'Detalle del Pedido',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
            if (_pedido?.noPedido != null)
              const Text(
                'Información del pedido',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarPedido,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 21,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: _buildBody(),
        ),
      ),

      bottomNavigationBar: disableBtn(_pedido)
        ? ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: BottomAppBar(
                  height: 70,
                  color: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.white,
                  shadowColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: SizedBox.expand(
                    child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          backgroundColor: const Color(0xff1a237e),
                          alignment: Alignment.center,
                        ),
                        onPressed: () => _confirmarMarcarPedido(context, null),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Marcar como entregado",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                    ),
                  )
              )
          )
        : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF1A237E),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_pedido == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGeneralCard(),

          const SizedBox(height: 16),

          _buildInfoEnvioCard(),

          const SizedBox(height: 16),

          _buildDetalleProductosCard(),
        ],
      ),
    );
  }

  Widget _buildInfoGeneralCard() {
    return _buildSectionCard(
      title: 'Información general',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.person_outline_rounded,
            label: 'Cliente',
            value: _pedido!.cliente ?? 'N/A',
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.credit_card_rounded,
            label: 'Tipo de venta',
            value: _pedido!.isSolicitudCredito == true
                ? 'Crédito'
                : 'Contado',
            badge: true,
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha de registro',
            value: formatedDate(
              _pedido!.fechaRegistro ?? 'N/A',
            ),
          ),

          const SizedBox(height: 20),

          // Información destacada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.indigo
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total acumulado',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'C\$ ${formattedNumber(_pedido?.totalAfecha ?? 0.00)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                          Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool badge = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.indigo,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 3),

                badge
                    ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: value == 'Crédito'
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: value == 'Crédito'
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                )
                    : Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoEnvioCard() {
    return _buildSectionCard(
      title: 'Datos de entrega',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.location_on_outlined,
            label: 'Enviar a',
            value: _pedido!.enviarA ?? 'N/A',
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.map_outlined,
            label: 'Ubicación',
            value: _pedido!.ubicacion ?? 'N/A',
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.route_outlined,
            label: 'Ruta',
            value: _pedido!.rutaCliente ?? 'N/A',
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.event_available_outlined,
            label: 'Entrega solicitada',
            value: formatedDate(
              _pedido!.fechaEntregaSolicitada ?? 'N/A',
            ),
          ),

          if (_pedido!.observaciones != null &&
              _pedido!.observaciones!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),

            _buildObservacionesCard(
              _pedido!.observaciones!,
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildObservacionesCard(String observaciones) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notes_rounded,
              size: 21,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Observaciones',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  observaciones,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleProductosCard() {
    if (_pedido!.detallePedido == null ||
        _pedido!.detallePedido!.isEmpty) {
      return const SizedBox.shrink();
    }

    final detalles = _pedido!.detallePedido!;

    return _buildSectionCard(
      title: 'Productos',
      icon: Icons.inventory_2_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${detalles.length}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF596273),
          ),
        ),
      ),

      child: Column(
        children: List.generate(
          detalles.length,
              (index) {
            final DetallePedidoModel item = detalles[index];

            final subtotalItem = (item.cantidad ?? 0) * (item.precioUnitarioAfecha ?? 0);

            return   _buildProductoItem(
              item,
              subtotalItem,
              index == detalles.length - 1,
              index,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductoItem(
      DetallePedidoModel item,
      double subtotalItem,
      bool isLast,
      int index,
      ) {
    final cantidad = item.cantidad?.toInt() ?? 0;
    final precioUnitario = item.precioUnitarioAfecha ?? 0.0;

    return disableBtn(_pedido) ? Dismissible(

      key: ValueKey(
        'prod_${item.codigoProducto ?? index}_$index',
      ),

      direction: DismissDirection.endToStart,

      onDismissed: (_) {
        eliminarProducto(index);
      },

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.red.shade400,
          size: 22,
        ),
      ),

      child: GestureDetector(
        onTap: () {
          if( _pedido?.estado?.toLowerCase() == 'entregado' || _pedido?.estado?.toLowerCase() == 'entrega parcial') return;

          showProducto(context, item);
        },
        child: Container(
          margin: EdgeInsets.only(
            bottom: isLast ? 0 : 10,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEAECEF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.indigo,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.producto ?? 'Producto desconocido',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202938),
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${cantidad.toString()} ${cantidad == 1 ? 'unidad' : 'unidades'}'
                          '  •  C\$ ${formattedNumber(precioUnitario)} c/u',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A94A6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if(disableBtn(_pedido)) InkWell(
                    onTap: () => eliminarProducto(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: 17,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'C\$ ${formattedNumber(subtotalItem)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) : Container(
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAECEF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.indigo,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto ?? 'Producto desconocido',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202938),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${cantidad.toString()} ${cantidad == 1 ? 'unidad' : 'unidades'}'
                      '  •  C\$ ${formattedNumber(precioUnitario)} c/u',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A94A6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if(disableBtn(_pedido)) InkWell(
                onTap: () => eliminarProducto(index),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 17,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'C\$ ${formattedNumber(subtotalItem)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EBF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF1A237E),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
              ),

              if (trailing != null) trailing,
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(
    IconData icon,
    String label,
    String value, {
      bool highlight = false,
    }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF8A94A6),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8496),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                  ? const Color(0xFF1A237E)
                  : const Color(0xFF293241),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFD32F2F),
                size: 30,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No pudimos cargar el pedido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202938),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8496),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _cargarPedido,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(
                  color: Color(0xFF1A237E),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Color(0xFFB0B7C3),
          ),
          SizedBox(height: 14),
          Text(
            'No se encontró el pedido',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF697386),
            ),
          ),
        ],
      ),
    );
  }
}