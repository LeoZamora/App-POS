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

Future<List<ProductoModel>> getProductos(String tipo) async {
  final String urlApi = '${server}api/Producto?tipoProducto=$tipo';
  try {
    final response = await http.get(Uri.parse(urlApi));
    if(response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);

      List<ProductoModel> productos = responseBody
          .map((item) => ProductoModel.fromMap(item as Map<String, dynamic>)).toList();
      print('Productos desde api: $productos');
      return productos;
    } else {
      print('Cuerpo de la respuesta: ${response.body}');
      throw Exception(
          'Falló al cargar la lista de productos (código: ${response.statusCode})');
      }
  } catch (e) {
    print('Error inesperado al obtener productos: $e');
    throw Exception('Ocurrió un error inesperado al obtener los productos.');
  }
}

Future<Map<String, dynamic>> postLogin(Map<String, String> data) async {
  final String urlApi = '${server}api/Usuario/Login';

  try{
    final reponse = await http.post(
      Uri.parse(urlApi),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(data)
    );

    if(reponse.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(reponse.body);
      return responseBody;
    } else {
      Map<String, dynamic> responseBody = jsonDecode(reponse.body);
      return responseBody;
    }
  } catch (e) {
    print('Error inesperado al iniciar sesión: $e');
    return {
      'error': 'Ocurrió un error inesperado al iniciar sesión.'
    };
  }
}

Future<Map<String, dynamic>?> postVentas(Map<String, dynamic> data) async {
  final String urlApi = '${server}api/Venta';

  try {
    final response = await http.post(Uri.parse(urlApi),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(data)
    );
    print('Response: ${response.statusCode}');
    if(response.statusCode == 201) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      return {
        "code": 201,
        "data": responseBody
      };
    } else {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      return responseBody;
    }

  } catch (e) {
    return {
      'error': 'Ocurrió un error inesperado al registrar la venta. $e'
    };
  }
}