import 'package:intl/intl.dart';

String formatedDate(String? fechaStr, {String formato = 'EEEE, d MMMM yyyy', String locale = 'es_ES'}) {
  print('fechaStr: $fechaStr');
  if (fechaStr == null || fechaStr.isEmpty) return 'Fecha inválida';

  try {
    final fecha = DateTime.parse(fechaStr);
    return DateFormat(formato, locale).format(fecha);
  } catch (e) {
    print('ERROR FECHA: $e');
    return 'Fecha inválida';
  }
}