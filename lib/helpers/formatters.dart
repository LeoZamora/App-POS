import 'package:intl/intl.dart';
import 'package:inversiones_ar/features/auth/models/authState.dart';

String formatedDate(String? fechaStr, {String formato = 'EEEE, d MMMM yyyy', String locale = 'es_ES'}) {
  if (fechaStr == null || fechaStr.isEmpty) return 'Fecha inválida';

  try {
    final fecha = DateTime.parse(fechaStr);
    return DateFormat(formato, locale).format(fecha);
  } catch (e) {
    return 'Fecha inválida';
  }
}

String formattedNumber(double monto) {
  return NumberFormat("#,##0.00", "es_US").format(monto);
}