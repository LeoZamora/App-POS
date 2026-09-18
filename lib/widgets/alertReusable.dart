import 'package:flutter/material.dart';

class AlertReusable {
  static Future<bool> show(
      BuildContext context, {
        required String title,
        required String message,
        String yesText = 'Sí',
        String noText = 'Cancelar',
        IconData? icon,
        Color? primaryColor,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Usamos el color principal de la app si no se provee uno
        final themeColor = primaryColor ?? Theme.of(context).primaryColor;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Bordes bien redondeados
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Se adapta al contenido
                children: [
                  Icon(
                    icon ?? Icons.help_outline_rounded,
                    size: 52,
                    color: themeColor,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      // Botón de Cancelar (Gris y Outline)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          // Al presionar NO, retornamos false
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            noText,
                            style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón de Confirmar (Color principal y Fill)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          // Al presionar SÍ, retornamos true
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            yesText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ),
        );
      },
    );

    return result ?? false;
  }

}