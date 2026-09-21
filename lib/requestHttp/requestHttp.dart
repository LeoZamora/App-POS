import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'dart:async';
import 'package:inversiones_ar/api/apiClient.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:inversiones_ar/dbModels/models_type.dart';

final String server = 'https://inversiones-zafiro.com/devodigital/';

Future<Response> postLogin(Map<String, String> data) async {
  const String urlApi = '/Usuario/Login';

  try {
    final response = await apiClient.post(
        urlApi,
        data: data
    );

    return response;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al iniciar sesión.');
  }
}

Future<List<VentaModel>> getVentas(Map<String, dynamic> body) async {
  final String urlApi = '/Venta/lista';
  final DateTime hoy = DateTime.now();

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  try {
    final response = await apiClient.post(urlApi, data: {
      "desde": body["desde"],
      "hasta": body["hasta"],
      "idCaja": body["idCaja"],
      "idCliente": body["idCliente"],
      "idRuta": body["idRuta"],
      "idAperturaCaja": body["idAperturaCaja"],
    });
    List<dynamic> responseBody = response.data;
    List<VentaModel> ventas = responseBody
        .map((item) => VentaModel.fromMap(item as Map<String, dynamic>)).toList();
    return ventas;
  } on DioException catch (e) {
    rethrow;
  } catch (e, stackTrace) {
    print('ERROR AL OBTENER VENTAS: $e');
    print('STACK TRACE: $stackTrace');
    throw Exception('Ocurrió un error inesperado al obtener las ventas.');
  }
}

Future<List<ClienteModel>> getClientes() async {
  final String urlApi = '/Cliente';

  try{
    final response = await apiClient.get(urlApi);
    List<dynamic> responseBody = response.data;
    List<ClienteModel> clientes = responseBody
        .map((item) => ClienteModel.fromMap(item as Map<String, dynamic>)).toList();
    return clientes;
  } on DioException catch (e) {
    print('Error inesperado al obtener clientes DIO: $e');
    rethrow;
  } catch (e) {
    print('Error inesperado al obtener clientes: $e');
    throw Exception('Ocurrió un error inesperado al obtener los clientes.');
  }
}

Future<ClienteCredito> getCreditoCliente(int idCliente) async {
  final String url = '/Cliente/$idCliente/detalle-credito';

  try {
    final response = await apiClient.get(url);

    final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

    final ClienteCredito clienteCredito = ClienteCredito.fromMap(responseBody);

    return clienteCredito;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error al validar el credito del cliente');
  }
}

Future<ClienteModel> getClienteById(int idCliente) async {
  // final String urlApi = '${server}api/Cliente/$idCliente';
  final String urlApi = '/Cliente/$idCliente';

  try{
    final response = await apiClient.get(urlApi);

    final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

    final ClienteModel cliente = ClienteModel.fromMap(responseBody);

    return cliente;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener los clientes. ${e.toString()}');
  }
}

Future<List<DetalleVentaModel>> getVentaById(int idVenta) async {
  final String urlApi = '/Venta/$idVenta';

  try{
    final response = await apiClient.get(urlApi);
    List<dynamic> listaDetallesJson = response.data["detalleVenta"]! as List<dynamic>;

    List<DetalleVentaModel> detalle = listaDetallesJson.map((item) {
      return DetalleVentaModel.fromMap(item as Map<String, dynamic>);
    }).toList();
    
    return detalle;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener la venta. ${e.toString()}');
  }
}

Future<List<ProductoModel>> getProducts(int idSubCategoria) async {
  final String urlApi = '/Producto/sesion-caja/listado?idSubCategoria=$idSubCategoria';
  try {
    final response = await apiClient.get(urlApi);
    final List<dynamic> responseBody = response.data as List<dynamic>;

    final List<ProductoModel> productos = responseBody
        .map<ProductoModel>((item) => ProductoModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return productos;
  } on DioException catch (e) {
    print('ERROR $e');
    rethrow;
  } catch (e) {
    print('ERROR $e');
    throw Exception('Ocurrió un error inesperado al obtener los productos.');
  }
}

Future<ProductoModel> getProductoById(int idProducto) async {
  final String urlApi = '/Producto/$idProducto';

  try{
    final response = await apiClient.get(urlApi);
      final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

      final ProductoModel producto = ProductoModel.fromMap(responseBody);

      return producto;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener el producto.');
  }
}

// VENTAS Y PEDIDOS
Future<Map<String, dynamic>?> postVentas(Map<String, dynamic> data, bool ventaRapida) async {
  final String urlApi = !ventaRapida ? '/v2/venta' : '/v2/ventas/ventas-rapidas';

  try {
    final response = await apiClient.post(
      urlApi,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      ),
      data: json.encode(data),
    );

    final dynamic body = response.data;
    print('RESPONSE RAW BODY: $body'); // deja este print por ahora para ver qué manda cada endpoint

    Map<String, dynamic> parsedBody;

    if (body is Map<String, dynamic>) {
      parsedBody = body;
    } else if (body is String && body.trim().isNotEmpty) {
      try {
        final decoded = json.decode(body);
        parsedBody = decoded is Map<String, dynamic>
            ? decoded
            : {'msg': decoded.toString()};
      } catch (_) {
        // El backend no devolvió JSON válido para este endpoint
        // (texto plano, sin comillas, etc.) -> usamos el texto tal cual
        // como mensaje, en vez de tronar con FormatException.
        parsedBody = {'msg': body};
      }
    } else {
      // Body vacío o de otro tipo -> no hay mensaje específico del
      // backend, pero la venta ya se registró (status 2xx), no debe
      // fallar por esto.
      parsedBody = {};
    }

    return {
      "code": response.statusCode,
      "msg": parsedBody['msg'] ?? parsedBody['message'] ?? 'Venta registrada correctamente',
      ...parsedBody,
    };
  } on DioException catch (e) {
    if (e.response != null && e.response?.data != null) {
      final dynamic errorBody = e.response!.data;

      Map<String, dynamic> parsedError;
      if (errorBody is Map<String, dynamic>) {
        parsedError = errorBody;
      } else if (errorBody is String && errorBody.trim().isNotEmpty) {
        try {
          final decoded = json.decode(errorBody);
          parsedError = decoded is Map<String, dynamic>
              ? decoded
              : {'msg': decoded.toString()};
        } catch (_) {
          parsedError = {'msg': errorBody};
        }
      } else {
        parsedError = {};
      }

      return {
        "code": parsedError['code'] ?? e.response?.statusCode,
        "msg": parsedError['msg'] ??
            parsedError['message'] ??
            'Error al registrar la venta',
      };
    }

    // Sin response (timeout, sin conexión, DNS, etc.): sí es un error
    // real de red, lo dejamos propagar al catch genérico de afuera.
    rethrow;
  } catch (e, stackTrace) {
    print('Stack trace: $stackTrace');
    throw Exception('Ocurrió un error inesperado al registrar la venta. $e');
  }
}


// Future<Map<String, dynamic>?> postVentas(Map<String, dynamic> data, bool ventaRapida) async {
//   final String urlApi = !ventaRapida ? '/v2/venta' : '/v2/ventas/ventas-rapidas';
//
//   try {
//     final response = await apiClient.post(urlApi,
//       options: Options(
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//         },
//       ),
//       data: json.encode(data)
//     );
//
//     // String responseBody = response.data as String;
//
//     final dynamic body = response.data;
//
//     final Map<String, dynamic> parsedBody = body is String
//         ? json.decode(body) as Map<String, dynamic>
//         : body as Map<String, dynamic>;
//
//     return {
//       "code": response.statusCode,
//       "msg": parsedBody['msg'] ?? parsedBody['message'] ?? '',
//       ...parsedBody,
//     };
//
//   } on DioException catch (e) {
//     // rethrow;
//     if (e.response != null && e.response?.data != null) {
//       final dynamic errorBody = e.response!.data;
//       final Map<String, dynamic> parsedError = errorBody is String
//           ? (json.decode(errorBody) as Map<String, dynamic>)
//           : errorBody as Map<String, dynamic>;
//
//       return {
//         "code": parsedError['code'] ?? e.response?.statusCode,
//         "msg": parsedError['msg'] ??
//             parsedError['message'] ??
//             'Error al registrar la venta',
//       };
//     }
//   } catch (e, stackTrace) {
//     print('Stack trace: $stackTrace');
//     throw Exception('Ocurrió un error inesperado al registrar la venta. $e');
//   }
// }

// Future<Map<String, dynamic>?> postVentas(Map<String, dynamic> data, bool ventaRapida) async {
//   final String urlApi = !ventaRapida ? 'Venta' : 'v2/ventas/ventas-rapidas';
//   print(data);
//   try {
//     final response = await apiClient.post(urlApi,
//         options: Options(
//           headers: <String, String>{
//             'Content-Type': 'application/json',
//           },
//         ),
//         data: json.encode(data)
//     );
//
//     String responseBody = response.data as String;
//
//     return {
//       "code": response.statusCode,
//       "msg": responseBody
//     };
//
//   } on DioException catch (e) {
//     rethrow;
//   } catch (e) {
//     throw Exception('Ocurrió un error inesperado al registrar la venta.');
//   }
// }

Future<Map<String, dynamic>?> postPedidos(Map<String, dynamic> data) async {
  final String urlApi = '/pedidos';
  try {
    final response = await apiClient.post(urlApi,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
        ),
        data: json.encode(data)
    );

    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al registrar el pedido.');
  }
}

Future<Map<String, dynamic>?> putPedidosEntrega(Map<String, dynamic> data, int idPedido) async {
  final String urlApi = '/pedidos/$idPedido/entrega';
  try {
    final response = await apiClient.put(urlApi,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
        ),
        data: json.encode(data)
    );

    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al registrar el pedido.');
  }
}

Future<List<PedidoDetalleModel>> getPedidoByDetails(Map<String, dynamic> data) async {
  final String urlApi = '/pedidos/listado';

  try {
    final response = await apiClient.post(urlApi,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
        ),
        data: json.encode(data)
    );

    List<dynamic> listaDetallesJson;

    // 2. EXTRACCIÓN SEGURA
    if (response.data is String) {
      // Por si Dio no lo parseó automáticamente a JSON
      listaDetallesJson = json.decode(response.data);
    } else if (response.data is List) {
      // Caso ideal: es una lista directa
      listaDetallesJson = response.data;
    } else if (response.data is Map) {
      // Si el backend devuelve un objeto con la lista adentro (muy común)
      // Ajusta 'data' por la llave que use tu backend (ej. 'pedidos', 'result')
      listaDetallesJson = response.data['data'] ?? [];
      print('Aviso: El backend devolvió un Map. Se extrajo la llave "data".');
    } else {
      throw Exception('El formato de respuesta no es ni List ni Map.');
    }

    // 3. MAPEO AL MODELO (Si falla aquí, el error es en tu fromMap)
    List<PedidoDetalleModel> detalle = listaDetallesJson.map((item) {
      try {
        return PedidoDetalleModel.fromMap(item as Map<String, dynamic>);
      } catch (mapError) {
        rethrow;
      }
    }).toList();

    return detalle;

  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Error interno: $e');
  }
}

Future<PedidoModelComplete> getPedidoById(int idPedido) async {
  final String url = '/pedidos/$idPedido';

  try {
    final response = await apiClient.get(url);

    final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

    final PedidoModelComplete pedido = PedidoModelComplete.fromMap(responseBody);

    return pedido;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener el pedido.');
  }
}


Future<int> getNumFact() async {
  final String urlApi = '${server}api/Venta/no-factura';
  final response = await http.get(Uri.parse(urlApi));

  if(response.statusCode == 201 || response.statusCode == 200) {
    return int.parse(response.body);
  } else {
    return 0;
  }
}

Future<ResumenCajaModel> getResumenCaja(int idCaja) async {
  final String url = '/aperturas-caja/$idCaja';

  try {
    final response = await apiClient.get(url);

    final Map<String, dynamic> responseBody = response.data;

    final ResumenCajaModel resumenCaja = ResumenCajaModel.fromMap(responseBody);

    return resumenCaja;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener el resumen de caja.');
  }
}

Future<ResumenTotalesModel> getResumenCajaTotales(int idCaja) async {
  final String url = '/cajas/$idCaja/apertura-vigente/resumen';

  try {
    final response = await apiClient.get(url);

    final Map<String, dynamic> responseBody = response.data;

    final ResumenTotalesModel resumenCaja = ResumenTotalesModel.fromMap(responseBody);

    return resumenCaja;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener el resumen de caja.');
  }
}

Future<List<GenericModelCombobox>> getCategoriaProductos() async {
  final String urlApi = '/CategoriaProducto/combobox';

  try {
    final response = await apiClient.get(urlApi);
    final List<dynamic> categorias = response.data as List<dynamic>;

    final List<GenericModelCombobox> categoriasModel = categorias.map((item) {
      return GenericModelCombobox.fromMap(item as Map<String, dynamic>);
    }).toList();

    return categoriasModel;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener los tipos de productos.');
  }
}

Future<List<GenericModelCombobox>> getSubCategoriaProductos(int idCategoria) async {
  final String urlApi = '/SubCatProducto/combobox?idCategoria=$idCategoria';

  try {
    final response = await apiClient.get(urlApi);
    final List<dynamic> subcategorias = response.data as List<dynamic>;

    final List<GenericModelCombobox> subcategoriasModel = subcategorias.map((item) {
      return GenericModelCombobox.fromMap(item as Map<String, dynamic>);
    }).toList();

     return subcategoriasModel;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener los tipos de productos.');
  }
}


// APERTURA Y CIERRE DE CAJA
Future<List<ProductoModel>> openCaja() async {
  final String url = '/aperturas-caja';

  try {
    final response = await apiClient.post(url);
    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al abrir la caja.');
  }
}

Future<Map<String, dynamic>> arquearCaja (Map<String, dynamic> data) async {
  final String url = '/arqueos-caja';

  try {
    final response = await apiClient.post(url, data: data);

    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e, stackTrace) {
    throw Exception('Ocurrió un error inesperado al abrir la caja.');
  }
}


Future<List<ProductoModel>> closeCaja() async {
  final String url = '/cierres-caja';

  try {
    final response = await apiClient.post(url);
    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al cerrar la caja.');
  }
}

Future<List<CajaModel>> getCajas(idUsuario) async {
  final String url = '/usuarios/cajas-autorizadas?idUsuario=$idUsuario';

  try {
    final response = await apiClient.get(url);
    print(response.data);
    final List<CajaModel> cajas = (response.data as List)
        .map((item) => CajaModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return cajas;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Error al procesar las cajas autorizadas: $e');
  }
}

Future<Map<String, dynamic>> getCajaActiva(idUsuario) async {
  final String url = '/usuarios/$idUsuario/caja-activa';

  try {
    final response = await apiClient.get(url);
    final Map<String, dynamic> responseBody = response.data;

    return responseBody;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Error al procesar las cajas autorizadas: $e');
  }
}

Future<Map<String, dynamic>> postAperturaCaja (Map<String, dynamic> data) async {
  final String url = '/aperturas-caja';

  try {
    final response = await apiClient.post(url, data: data);

    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e, stackTrace) {
   throw Exception('Ocurrió un error inesperado al abrir la caja.');
  }
}

Future<AperturaCajaModel> getAperturaCaja(int idCaja) async {
  final String url = '/cajas/$idCaja/apertura-vigente';
  try {
    final response = await apiClient.get(url);
    final Map<String, dynamic> responseBody = response.data;
    final AperturaCajaModel aperturaCaja = AperturaCajaModel.fromMap(responseBody);
    return aperturaCaja;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener la apertura de caja.');
  }
}


Future<Map<String, dynamic>>  postRetiroEfectivo(Map<String, dynamic> data) async {
  final String url = '/retiros-caja';

  try {
    final response = await apiClient.post(url, data: data);

    return response.data;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al abrir la caja.');
  }
}

Future<List<GenericModelCombobox>> getConceptosCombobox() async {
  final String urlApi = '/conceptos-tipo-mov/retiros-caja/combobox';

  try {
    final response = await apiClient.get(urlApi);
    final List<dynamic> categorias = response.data as List<dynamic>;

    final List<GenericModelCombobox> categoriasModel = categorias.map((item) {
      return GenericModelCombobox.fromMap(item as Map<String, dynamic>);
    }).toList();

    return categoriasModel;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Ocurrió un error inesperado al obtener los tipos de productos.');
  }
}

Future<List<RetiroEfectivoModel>> getRetirosEfectivo(int idApertura) async {
  final String url = '/retiros-caja?idAperturaCaja=$idApertura';

  try {
    final response = await apiClient.get(url);

    final List<dynamic> responseBody = response.data as List<dynamic>;

    final List<RetiroEfectivoModel> retiros = responseBody.map((item) {
      return RetiroEfectivoModel.fromMap(item as Map<String, dynamic>);
    }).toList();

    return retiros;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Error al procesar las cajas autorizadas: $e');
  }
}

Future<RetiroEfectivoModel> getRetirosEfectivoById(int idRetiroCaja) async {
  final String url = '/retiros-caja/$idRetiroCaja';

  try {
    final response = await apiClient.get(url);

    final RetiroEfectivoModel retiro = RetiroEfectivoModel.fromMap(response.data as Map<String, dynamic>);

    return retiro;
  } on DioException catch (e) {
    rethrow;
  } catch (e) {
    throw Exception('Error al procesar las cajas autorizadas: $e');
  }
}

// Future<bool> getParametroFirebase() async {
//   final remoteConfig = FirebaseRemoteConfig.instance;
//
//   await remoteConfig.setConfigSettings(
//     RemoteConfigSettings(
//       fetchTimeout: const Duration(seconds: 10),
//       minimumFetchInterval: const Duration(hours: 1),
//     ),
//   );
//
//   await remoteConfig.fetchAndActivate();
//   return remoteConfig.getBool('editFact');
// }