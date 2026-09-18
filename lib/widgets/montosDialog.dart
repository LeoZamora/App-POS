import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ShowDialogMontos extends StatefulWidget {
  final Future<void> Function() impimir;
  final double montoTotal;
  late bool isLoaded;

  ShowDialogMontos({super.key,
    required this.montoTotal,
    required this.impimir,
    required this.isLoaded,
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

  String formattedNumber(double monto) {
    return NumberFormat("#,##0.00", "es_US").format(monto);
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
            'Total a pagar: \$${ widget.montoTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _montoPagoController,
            keyboardType: TextInputType.number,
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
            onPressed: widget.isLoaded ? null : () async {
              print('Monto recibido: ${formattedNumber(double.parse(_montoPagoController.text))}');
              final double monto = double.parse(_montoPagoController.text);
              if (monto >= widget.montoTotal) {
                setState(() {
                  widget.isLoaded = true;
                });
                try {
                  await widget.impimir();
                  Navigator.pop(context, {
                    'pago': double.tryParse(_montoPagoController.text) ?? 0.0,
                    'cambio': _cambio,
                  });
                } finally {
                  setState(() {
                    widget.isLoaded = false;
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El pago es insuficiente.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              // padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.isLoaded
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
