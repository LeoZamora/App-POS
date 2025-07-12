import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'dart:async';

final String server = 'http://165.98.133.202:55478/';

Future<List<VentaModel>> getVentas() async {
  final String urlApi = '${server}api/Venta';
  // final String urlApi = 'http://localhost:5091/api/Venta';
  try {
    final response = await http.get(Uri.parse(urlApi));
    if(response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);
      List<VentaModel> ventas = responseBody
          .map((item) => VentaModel.fromMap(item as Map<String, dynamic>)).toList();
      return ventas;

    } else {
      print('Error en la solicitud: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      throw Exception(
          'Falló al cargar la lista de ventas (código: ${response.statusCode})');
    }
  } catch (e) {
    print('Error inesperado al obtener ventas: $e');
    throw Exception('Ocurrió un error inesperado al obtener las ventas.');
  }
}

Future<List<ClienteModel>> getClientes() async {
  final String urlApi = '${server}api/Cliente';

  try{
    final response = await http.get(Uri.parse(urlApi));
    if(response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);
      List<ClienteModel> clientes = responseBody
          .map((item) => ClienteModel.fromMap(item as Map<String, dynamic>)).toList();
      print(clientes);
      return clientes;
    } else {
      print('Error en la solicitud: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      throw Exception(
          'Falló al cargar la lista de clientes (código: ${response.statusCode})');
    }
  } catch (e) {
    print('Error inesperado al obtener clientes: $e');
    throw Exception('Ocurrió un error inesperado al obtener los clientes.');
  }
}