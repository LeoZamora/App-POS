import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class ToastSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        ToastType type = ToastType.warning,
        Duration duration = const Duration(seconds: 3),
      }) {
    // Definimos colores e íconos según el tipo de mensaje
    final config = _getToastConfig(type);

    ScaffoldMessenger.of(context).clearSnackBars(); // Limpia otros avisos previos

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating, // Flotante con bordes redondeados
        backgroundColor: Colors.transparent, // Transparente para usar nuestro Container
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono contextual
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: config.iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config.icon,
                  color: config.iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Texto del mensaje
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.error:
        return _ToastConfig(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade700,
          iconBackgroundColor: Colors.red.shade50,
          backgroundColor: Colors.white,
          borderColor: Colors.red.shade100,
        );
      case ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade900,
          iconBackgroundColor: Colors.amber.shade50,
          backgroundColor: Colors.white,
          borderColor: Colors.amber.shade200,
        );
      case ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.green.shade700,
          iconBackgroundColor: Colors.green.shade50,
          backgroundColor: Colors.white,
          borderColor: Colors.green.shade100,
        );
      case ToastType.info:
        return _ToastConfig(
          icon: Icons.info_outline_rounded,
          iconColor: Colors.indigo.shade700,
          iconBackgroundColor: Colors.indigo.shade50,
          backgroundColor: Colors.white,
          borderColor: Colors.indigo.shade100,
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;

  _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}