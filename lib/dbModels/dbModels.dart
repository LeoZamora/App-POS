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
  int? idSubCatProd;
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
  bool? estado;

  ProductoModel({
    this.idProducto,
    this.idSubCatProd,
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
      'idSubCatProd': idSubCatProd,
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
      idSubCatProd: map['idSubCatProd'],
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
  bool? estado;

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
      'estado': estado == true ? 1 : 0,
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
      estado: map['estado'] == 1,
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
  String? cliente;
  bool? credito;
  String? observaciones;
  String? enviarA;
  String? ubicacion;
  bool sincronizada;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;
  double? total;

  VentaModel({
    this.idVenta,
    this.noVenta,
    this.idCliente,
    this.cliente,
    this.credito,
    this.observaciones,
    this.enviarA,
    this.ubicacion,
    required this.sincronizada,
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
      'cliente': cliente,
      'credito': credito,
      'observaciones': observaciones,
      'enviarA': enviarA,
      'ubicacion': ubicacion,
      'sincronizada': sincronizada,
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
      cliente: map['cliente'],
      credito: map['credito'],
      observaciones: map['observaciones'],
      enviarA: map['enviarA'],
      ubicacion: map['ubicacion'],
      sincronizada: map['sincronizada'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'],
      total: map['total'],
    );
  }
}

class DetalleVentaModel {
  int? IdDetalleVenta;
  int? idVenta;
  int? idProducto;
  double? cantidad;
  double? precioUnitario;
  String? observaciones;

  DetalleVentaModel({
    this.IdDetalleVenta,
    this.idVenta,
    this.idProducto,
    this.cantidad,
    this.precioUnitario,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'IdDetalleVenta': IdDetalleVenta,
      'idVenta': idVenta,
      'idProducto': idProducto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'observaciones': observaciones,
    };
  }

  factory DetalleVentaModel.fromMap(Map<String, dynamic> map) {
    return DetalleVentaModel(
      IdDetalleVenta: map['IdDetalleVenta'],
      idVenta: map['idVenta'],
      idProducto: map['idProducto'],
      cantidad: map['cantidad'],
      precioUnitario: map['precioUnitario'],
      observaciones: map['observaciones'],
    );
  }
}

class TipoProductoModel {
  int? idTipoProducto;
  String? nombre;

  TipoProductoModel({
    this.idTipoProducto,
    this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'idTipoProducto': idTipoProducto,
      'nombre': nombre,
    };
  }

  factory TipoProductoModel.fromMap(Map<String, dynamic> map) {
    return TipoProductoModel(
      idTipoProducto: map['idTipoProducto'],
      nombre: map['nombre'],
    );
  }
}


// {
// "noVenta": "string",
// "idCliente": 0,
// "credito": true,
// "observaciones": "string",
// "enviarA": "string",
// "usuarioRegistro": "string",
// "detalleVenta": [
// {
// "idVenta": 0,
// "idProducto": 0,
// "cantidad": 0,
// "precioUnitario": 0,
// "observaciones": "string"
// }
// ]
// }
