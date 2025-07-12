import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CategoriasModel {
  int? idCategoriaProducto;
  String? nombre;
  String? fechaRegistro;
  String? usuarioRegistro;
  int? estado;

  CategoriasModel({
    this.idCategoriaProducto,
    this.nombre,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCategoriaProducto': idCategoriaProducto,
      'nombre': nombre,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory CategoriasModel.fromMap(Map<String, dynamic> map) {
    return CategoriasModel(
      idCategoriaProducto: map['idCategoriaProducto'],
      nombre: map['nombre'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class UnidadMedidaModel {
  int? idUnidadMedida;
  String? abreviatura;
  String? nombre;
  String? fechaRegistro;
  String? usuarioRegistro;
  int? estado;

  UnidadMedidaModel({
    this.idUnidadMedida,
    this.abreviatura,
    this.nombre,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idUnidadMedida': idUnidadMedida,
      'abreviatura': abreviatura,
      'nombre': nombre,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory UnidadMedidaModel.fromMap(Map<String, dynamic> map) {
    return UnidadMedidaModel(
      idUnidadMedida: map['idUnidadMedida'],
      abreviatura: map['abreviatura'],
      nombre: map['nombre'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class ProductoModel {
  int? idProducto;
  int? IdSubCatProd;
  int? idUnidadMedida;
  String? codigo;
  String? nombre;
  double? precio;
  double? costo;
  double? cantidadTotal;
  double? cantidadMinima;
  String? imagen;
  String? observaciones;
  String? tipoProducto;
  String? fechaRegistro;
  String? usuarioRegistro;
  int? estado;

  ProductoModel({
    this.idProducto,
    this.IdSubCatProd,
    this.idUnidadMedida,
    this.codigo,
    this.nombre,
    this.precio,
    this.costo,
    this.cantidadTotal,
    this.cantidadMinima,
    this.imagen,
    this.observaciones,
    this.tipoProducto,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProducto': idProducto,
      'IdSubCatProd': IdSubCatProd,
      'idUnidadMedida': idUnidadMedida,
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'costo': costo,
      'cantidadTotal': cantidadTotal,
      'cantidadMinima': cantidadMinima,
      'imagen': imagen,
      'observaciones': observaciones,
      'tipoProducto': tipoProducto,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      idProducto: map['idProducto'],
      IdSubCatProd: map['IdSubCatProd'],
      idUnidadMedida: map['idUnidadMedida'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      precio: map['precio'],
      costo: map['costo'],
      cantidadTotal: map['cantidadTotal'],
      cantidadMinima: map['cantidadMinima'],
      imagen: map['imagen'],
      observaciones: map['observaciones'],
      tipoProducto: map['tipoProducto'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class CategoriaClienteModel {
  int? idCategoriaCliente;
  String? nombre;
  String? descripcion;
  String? fechaRegistro;
  String? usuarioRegistro;
  int? estado;

  CategoriaClienteModel({
    this.idCategoriaCliente,
    this.nombre,
    this.descripcion,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCategoriaCliente': idCategoriaCliente,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory CategoriaClienteModel.fromMap(Map<String, dynamic> map) {
    return CategoriaClienteModel(
      idCategoriaCliente: map['idCategoriaCliente'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class ClienteModel {
  int? idCliente;
  int? idCategoriaCliente;
  String? codigo;
  String? direccion;
  String? telefono;
  String? departamento;
  String? municipio;
  bool? personaNatural;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;

  ClienteModel({
    this.idCliente,
    this.idCategoriaCliente,
    this.codigo,
    this.direccion,
    this.telefono,
    this.departamento,
    this.municipio,
    this.personaNatural,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCliente': idCliente,
      'idCategoriaCliente': idCategoriaCliente,
      'codigo': codigo,
      'direccion': direccion,
      'telefono': telefono,
      'departamento': departamento,
      'municipio': municipio,
      'personaNatural': personaNatural,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      idCliente: map['idCliente'],
      idCategoriaCliente: map['idCategoriaCliente'],
      codigo: map['codigo'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      departamento: map['departamento'],
      municipio: map['municipio'],
      personaNatural: map['personaNatural'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class TipoProveedorModel {
  int? idTipoProveedor;
  String? nombre;
  String? observaciones;
  String? fechaRegistro;
  String? usuarioRegistro;
  int? estado;

  TipoProveedorModel({
    this.idTipoProveedor,
    this.nombre,
    this.observaciones,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idTipoProveedor': idTipoProveedor,
      'nombre': nombre,
      'observaciones': observaciones,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory TipoProveedorModel.fromMap(Map<String, dynamic> map) {
    return TipoProveedorModel(
      idTipoProveedor: map['idTipoProveedor'],
      nombre: map['nombre'],
      observaciones: map['observaciones'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class ProveedorModel {
  int? idProveedor;
  int? idTipoProveedor;
  String? nombre;
  String? departamento;
  String? municipio;
  String? direccion;
  String? telefono;
  String? fechaRegistro;
  int? usuarioRegistro;
  int? estado;

  ProveedorModel({
    this.idProveedor,
    this.idTipoProveedor,
    this.nombre,
    this.departamento,
    this.municipio,
    this.direccion,
    this.telefono,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProveedor': idProveedor,
      'idTipoProveedor': idTipoProveedor,
      'nombre': nombre,
      'departamento': departamento,
      'municipio': municipio,
      'direccion': direccion,
      'telefono': telefono,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory ProveedorModel.fromMap(Map<String, dynamic> map) {
    return ProveedorModel(
      idProveedor: map['idProveedor'],
      idTipoProveedor: map['idTipoProveedor'],
      nombre: map['nombre'],
      departamento: map['departamento'],
      municipio: map['municipio'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class ProveedorProductoModel {
  int? idProveedorProducto;
  int? idProveedor;
  int? idProducto;
  String? observaciones;
  int? Predeterminado;
  String? fechaRegistro;
  int? usuarioRegistro;
  int? estado;

  ProveedorProductoModel({
    this.idProveedorProducto,
    this.idProveedor,
    this.idProducto,
    this.observaciones,
    this.Predeterminado,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProveedorProducto': idProveedorProducto,
      'idProveedor': idProveedor,
      'idProducto': idProducto,
      'observaciones': observaciones,
      'Predeterminado': Predeterminado,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory ProveedorProductoModel.fromMap(Map<String, dynamic> map) {
    return ProveedorProductoModel(
      idProveedorProducto: map['idProveedorProducto'],
      idProveedor: map['idProveedor'],
      idProducto: map['idProducto'],
      observaciones: map['observaciones'],
      Predeterminado: map['Predeterminado'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
    );
  }
}

class VentaModel {
  int? idVenta;
  String? noVenta;
  int? idCliente;
  bool? credito;
  String? observaciones;
  String? enviarA;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;
  double? total;

  VentaModel({
    this.idVenta,
    this.noVenta,
    this.idCliente,
    this.credito,
    this.observaciones,
    this.enviarA,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
    this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'idVenta': idVenta,
      'noVenta': noVenta,
      'idCliente': idCliente,
      'credito': credito,
      'observaciones': observaciones,
      'enviarA': enviarA,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
      'total': total,
    };
  }

  factory VentaModel.fromMap(Map<String, dynamic> map) {
    return VentaModel(
      idVenta: map['idVenta'],
      noVenta: map['noVenta'],
      idCliente: map['idCliente'],
      credito: map['credito'],
      observaciones: map['observaciones'],
      enviarA: map['enviarA'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
      total: map['total'],
    );
  }

  Future<VentaModel> fetchAlbum() async {
    final response = await http.get(Uri.parse('http://localhost:5091/api/Venta'));
    if (response.statusCode == 200) {
      return VentaModel.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load album');
    }
  }
}

class DetalleVentaModel {
  int? IdDetalleVenta;
  int? idVenta;
  int? idProducto;
  double? Cantidad;
  double? precioUnitario;
  String? observaciones;

  DetalleVentaModel({
    this.IdDetalleVenta,
    this.idVenta,
    this.idProducto,
    this.Cantidad,
    this.precioUnitario,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'IdDetalleVenta': IdDetalleVenta,
      'idVenta': idVenta,
      'idProducto': idProducto,
      'Cantidad': Cantidad,
      'precioUnitario': precioUnitario,
      'observaciones': observaciones,
    };
  }

  factory DetalleVentaModel.fromMap(Map<String, dynamic> map) {
    return DetalleVentaModel(
      IdDetalleVenta: map['IdDetalleVenta'],
      idVenta: map['idVenta'],
      idProducto: map['idProducto'],
      Cantidad: map['Cantidad'],
      precioUnitario: map['precioUnitario'],
      observaciones: map['observaciones'],
    );
  }
}
