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

class GenericModelCombobox {
  int? id;
  String? nombre;
  String? codigo;

  GenericModelCombobox({
    this.id,
    this.nombre,
    this.codigo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
    };
  }

  factory GenericModelCombobox.fromMap(Map<String, dynamic> map) {
    return GenericModelCombobox(
      id: map['id'],
      nombre: map['nombre'],
      codigo: map['codigo'],
    );
  }
}

class AperturaCajaModel {
  int? idAperturaCaja;
  int? idCaja;
  String? cajaCodigo;
  String? cajaNombre;
  String? codigo;
  String? observaciones;
  int? idUsuarioApertura;
  String? usuarioAperturaNombre;
  String? fechaApertura;
  double? montoAperturaEfectivo;
  double? montoAperturaMercaderia;
  int? idDesgloceCaja;
  double? totalDesgloce;
  bool? estado;

  AperturaCajaModel({
    this.idAperturaCaja,
    this.idCaja,
    this.cajaCodigo,
    this.cajaNombre,
    this.codigo,
    this.observaciones,
    this.idUsuarioApertura,
    this.usuarioAperturaNombre,
    this.fechaApertura,
    this.montoAperturaEfectivo,
    this.montoAperturaMercaderia,
    this.idDesgloceCaja,
    this.totalDesgloce,
    this.estado
  });

  Map<String, dynamic> toMap() {
    return {
      'idAperturaCaja': idAperturaCaja,
      'idCaja': idCaja,
      'cajaCodigo': cajaCodigo,
      'cajaNombre': cajaNombre,
      'codigo': codigo,
      'observaciones': observaciones,
      'idUsuarioApertura': idUsuarioApertura,
      'usuarioAperturaNombre': usuarioAperturaNombre,
      'fechaApertura': fechaApertura,
      'montoAperturaEfectivo': montoAperturaEfectivo,
      'montoAperturaMercaderia': montoAperturaMercaderia,
      'idDesgloceCaja': idDesgloceCaja,
      'totalDesgloce': totalDesgloce,
      'estado': estado,
    };
  }

  factory AperturaCajaModel.fromMap(Map<String, dynamic> map) {
    return AperturaCajaModel(
      idAperturaCaja: map['idAperturaCaja'],
      idCaja: map['idCaja'],
      cajaCodigo: map['cajaCodigo'],
      cajaNombre: map['cajaNombre'],
      codigo: map['codigo'],
      observaciones: map['observaciones'],
      idUsuarioApertura: map['idUsuarioApertura'],
      usuarioAperturaNombre: map['usuarioAperturaNombre'],
      fechaApertura: map['fechaApertura'],
      montoAperturaEfectivo: map['montoAperturaEfectivo'],
      montoAperturaMercaderia: map['montoAperturaMercaderia'],
      idDesgloceCaja: map['idDesgloceCaja'],
      totalDesgloce: map['totalDesgloce'],
      estado: map['estado'],
    );
  }
}


class ResumenCajaModel {
  int? idAperturaCaja;
  int? idCaja;
  String? cajaCodigo;
  String? cajaNombre;
  String? codigo;
  String? observaciones;
  int? idUsuarioApertura;
  String? usuarioAperturaNombre;
  String? fechaApertura;
  double? montoAperturaEfectivo;
  double? montoAperturaMercaderia;
  int? idDesgloceCaja;
  double? totalDesgloce;
  bool? estado;

  ResumenCajaModel({
    this.idAperturaCaja,
    this.idCaja,
    this.cajaCodigo,
    this.cajaNombre,
    this.codigo,
    this.observaciones,
    this.idUsuarioApertura,
    this.usuarioAperturaNombre,
    this.fechaApertura,
    this.montoAperturaEfectivo,
    this.montoAperturaMercaderia,
    this.idDesgloceCaja,
    this.totalDesgloce,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'idAperturaCaja': idAperturaCaja,
      'idCaja': idCaja,
      'cajaCodigo': cajaCodigo,
      'cajaNombre': cajaNombre,
      'codigo': codigo,
      'observaciones': observaciones,
      'idUsuarioApertura': idUsuarioApertura,
      'usuarioAperturaNombre': usuarioAperturaNombre,
      'fechaApertura': fechaApertura,
      'montoAperturaEfectivo': montoAperturaEfectivo,
      'montoAperturaMercaderia': montoAperturaMercaderia,
      'idDesgloceCaja': idDesgloceCaja,
      'totalDesgloce': totalDesgloce,
      'estado': estado,
    };
  }

  factory ResumenCajaModel.fromMap(Map<String, dynamic> map) {
    return ResumenCajaModel(
      idAperturaCaja: map['idAperturaCaja'],
      idCaja: map['idCaja'],
      cajaCodigo: map['cajaCodigo'],
      cajaNombre: map['cajaNombre'],
      codigo: map['codigo'],
      observaciones: map['observaciones'],
      idUsuarioApertura: map['idUsuarioApertura'],
      usuarioAperturaNombre: map['usuarioAperturaNombre'],
      fechaApertura: map['fechaApertura'],
      montoAperturaEfectivo: map['montoAperturaEfectivo'],
      montoAperturaMercaderia: map['montoAperturaMercaderia'],
      idDesgloceCaja: map['idDesgloceCaja'],
      totalDesgloce: map['totalDesgloce'],
      estado: map['estado'],
    );
  }
}

class ResumenTotalesModel {
  double? totalVentas;
  double? totalMercaderia;
  double? efectivoApertura;
  double? totalEnCaja;
  double? totalRetiros;
  double? totalPedidos;

  ResumenTotalesModel({
    this.totalVentas,
    this.totalMercaderia,
    this.efectivoApertura,
    this.totalRetiros,
    this.totalEnCaja,
    this.totalPedidos,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalVentas': totalVentas,
      'totalMercaderia': totalMercaderia,
      'efectivoApertura': efectivoApertura,
      'totalRetiros': totalRetiros,
      'totalEnCaja': totalEnCaja,
      'totalPedidos': totalPedidos,
    };
  }


  factory ResumenTotalesModel.fromMap(Map<String, dynamic> map) {
    return ResumenTotalesModel(
      totalVentas: map['totalVentas'],
      totalMercaderia: map['totalMercaderia'],
      efectivoApertura: map['efectivoApertura'],
      totalRetiros: map['totalRetiros'],
      totalEnCaja: map['totalEnCaja'],
      totalPedidos: map['totalPedidos'],
    );
  }
}

// PEDIDOS
class DetallePedidoModel {
  int? idDetallePedido;
  int? idPedido;
  int? idProducto;
  String? producto;
  double? cantidad;
  String? codigoProducto;
  double? precioUnitario;
  double? costoUnitario;
  double? precioUnitarioAfecha;
  double? costoUnitarioAfecha;
  String? observaciones;

  DetallePedidoModel({
    this.idDetallePedido,
    this.idPedido,
    this.idProducto,
    this.cantidad,
    this.codigoProducto,
    this.observaciones,
    this.producto,
    this.precioUnitario,
    this.costoUnitario,
    this.precioUnitarioAfecha,
    this.costoUnitarioAfecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'idDetallePedido': idDetallePedido,
      'idPedido': idPedido,
      'idProducto': idProducto,
      'cantidad': cantidad,
      'codigoProducto': codigoProducto,
      'observaciones': observaciones,
      'producto': producto,
      'precioUnitario': precioUnitario,
      'CostoUnitario': costoUnitario,
      'precioUnitarioAfecha': precioUnitarioAfecha,
      'CostoUnitarioAfecha': costoUnitarioAfecha,
    };
  }

  factory DetallePedidoModel.fromMap(Map<String, dynamic> map) {
    return DetallePedidoModel(
      idDetallePedido: map['idDetallePedido'],
      idPedido: map['idPedido'],
      idProducto: map['idProducto'],
      cantidad: map['cantidad'],
      codigoProducto: map['codigoProducto'],
      observaciones: map['observaciones'],
      producto: map['producto'],
      precioUnitario: (map['precioUnitario']),
      costoUnitario: (map['CostoUnitario']),
      precioUnitarioAfecha: (map['precioUnitarioAfecha']),
      costoUnitarioAfecha: (map['CostoUnitarioAfecha']),
    );
  }
}

class PedidoModel {
  int? idPedido;
  int? idAperturaCaja;
  int? idCliente;
  String? cliente;
  bool? isSolicitudCredito;
  String? observaciones;
  String? enviarA;
  String? ubicacion;
  String? fechaEntregaSolicitada;
  String? usuarioRegistro;
  DetallePedidoModel? detallePedido;

  PedidoModel({
    this.idPedido,
    this.idAperturaCaja,
    this.idCliente,
    this.cliente,
    this.isSolicitudCredito,
    this.observaciones,
    this.enviarA,
    this.ubicacion,
    this.fechaEntregaSolicitada,
    this.usuarioRegistro,
    this.detallePedido,
  });

  Map<String, dynamic> toMap() {
    return {
      'idPedido': idPedido,
      'idAperturaCaja': idAperturaCaja,
      'idCliente': idCliente,
      'cliente': cliente,
      'isSolicitudCredito': isSolicitudCredito,
      'observaciones': observaciones,
      'enviarA': enviarA,
      'ubicacion': ubicacion,
      'fechaEntregaSolicitada': fechaEntregaSolicitada,
      'usuarioRegistro': usuarioRegistro,
      'detallePedido': detallePedido?.toMap(),
    };
  }

  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      idPedido: map['idPedido'],
      idAperturaCaja: map['idAperturaCaja'],
      idCliente: map['idCliente'],
      cliente: map['cliente'],
      isSolicitudCredito: map['isSolicitudCredito'],
      observaciones: map['observaciones'],
      enviarA: map['enviarA'],
      ubicacion: map['ubicacion'],
      fechaEntregaSolicitada: map['fechaEntregaSolicitada'],
      usuarioRegistro: map['usuarioRegistro'],
      detallePedido: map['detallePedido'] != null ? DetallePedidoModel.fromMap(map['detallePedido']) : null,
    );
  }
}

class PedidoDetalleModel {
  int? idPedido;
  String? noPedido;
  int? idAperturaCaja;
  int? idCliente;
  String? cliente;
  bool? isSolicitudCredito;
  String? observaciones;
  String? enviarA;
  String? fechaRegistro;
  String? usuarioRegistro;
  String? ubicacion;
  String? fechaEntregaSolicitada;
  String? fechaEntregaProgramada;
  int? idEstadoActual;
  String? estado;
  double? totalAfecha;
  String? fechaAtencion;
  String? fechaEntregado;
  DetallePedidoModel? detallePedido;


  PedidoDetalleModel({
    this.idPedido,
    this.noPedido,
    this.idAperturaCaja,
    this.idCliente,
    this.cliente,
    this.isSolicitudCredito,
    this.observaciones,
    this.enviarA,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.ubicacion,
    this.fechaEntregaSolicitada,
    this.fechaEntregaProgramada,
    this.idEstadoActual,
    this.estado,
    this.totalAfecha,
    this.fechaAtencion,
    this.fechaEntregado,
    this.detallePedido,
  });

  Map<String, dynamic> toMap() {
    return {
      'idPedido': idPedido,
      'noPedido': noPedido,
      'idAperturaCaja': idAperturaCaja,
      'idCliente': idCliente,
      'cliente': cliente,
      'isSolicitudCredito': isSolicitudCredito,
      'observaciones': observaciones,
      'enviarA': enviarA,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'ubicacion': ubicacion,
      'fechaEntregaSolicitada': fechaEntregaSolicitada,
      'fechaEntregaProgramada': fechaEntregaProgramada,
      'idEstadoActual': idEstadoActual,
      'estado': estado,
      'totalAfecha': totalAfecha,
      'fechaAtencion': fechaAtencion,
      'fechaEntregado': fechaEntregado,
      'detallePedido': detallePedido?.toMap(),
    };
  }

  factory PedidoDetalleModel.fromMap(Map<String, dynamic> map) {
    return PedidoDetalleModel(
      idPedido: map['idPedido'],
      noPedido: map['noPedido'],
      idAperturaCaja: map['idAperturaCaja'],
      idCliente: map['idCliente'],
      cliente: map['cliente'],
      isSolicitudCredito: map['isSolicitudCredito'],
      observaciones: map['observaciones'],
      enviarA: map['enviarA'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      ubicacion: map['ubicacion'],
      fechaEntregaSolicitada: map['fechaEntregaSolicitada'],
      fechaEntregaProgramada: map['fechaEntregaProgramada'],
      idEstadoActual: map['idEstadoActual'],
      estado: map['estado'],
      totalAfecha: map['totalAfecha'],
      fechaAtencion: map['fechaAtencion'],
      fechaEntregado: map['fechaEntregado'],
      detallePedido: map['detallePedido'] != null ? DetallePedidoModel.fromMap(map['detallePedido']) : null,
    );
  }
}

class PedidoModelComplete {
  int? idPedido;
  String? noPedido;
  int? idAperturaCaja;
  int? idCliente;
  String? cliente;
  bool? isSolicitudCredito;
  String? observaciones;
  String? enviarA;
  String? fechaRegistro;
  String? usuarioRegistro;
  String? ubicacion;
  String? fechaEntregaSolicitada;
  String? fechaEntregaProgramada;
  int? idEstadoActual;
  String? estado;
  double? totalAfecha;
  String? fechaAtencion;
  String? fechaEntregado;
  String? rutaCliente;
  String? aperturaCajaCodigo;
  String? aperturaCajaCaja;
  String? aperturaCajaUsuario;
  List<DetallePedidoModel>? detallePedido;


  PedidoModelComplete({
    this.idPedido,
    this.noPedido,
    this.idAperturaCaja,
    this.idCliente,
    this.cliente,
    this.isSolicitudCredito,
    this.observaciones,
    this.enviarA,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.ubicacion,
    this.fechaEntregaSolicitada,
    this.fechaEntregaProgramada,
    this.idEstadoActual,
    this.estado,
    this.totalAfecha,
    this.fechaAtencion,
    this.fechaEntregado,
    this.rutaCliente,
    this.aperturaCajaCodigo,
    this.aperturaCajaCaja,
    this.aperturaCajaUsuario,
    this.detallePedido,
  });

  Map<String, dynamic> toMap() {
    return {
      'idPedido': idPedido,
      'noPedido': noPedido,
      'idAperturaCaja': idAperturaCaja,
      'idCliente': idCliente,
      'cliente': cliente,
      'isSolicitudCredito': isSolicitudCredito,
      'observaciones': observaciones,
      'enviarA': enviarA,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'ubicacion': ubicacion,
      'fechaEntregaSolicitada': fechaEntregaSolicitada,
      'fechaEntregaProgramada': fechaEntregaProgramada,
      'idEstadoActual': idEstadoActual,
      'estado': estado,
      'totalAfecha': totalAfecha,
      'fechaAtencion': fechaAtencion,
      'fechaEntregado': fechaEntregado,
      'rutaCliente': rutaCliente,
      'aperturaCajaCodigo': aperturaCajaCodigo,
      'aperturaCajaCaja': aperturaCajaCaja,
      'aperturaCajaUsuario': aperturaCajaUsuario,
      'detallePedido': detallePedido?.map((x) => x.toMap()).toList(),
    };
  }

  factory PedidoModelComplete.fromMap(Map<String, dynamic> map) {
    return PedidoModelComplete(
      idPedido: map['idPedido'],
      noPedido: map['noPedido'],
      idAperturaCaja: map['idAperturaCaja'],
      idCliente: map['idCliente'],
      cliente: map['cliente'],
      isSolicitudCredito: map['isSolicitudCredito'],
      observaciones: map['observaciones'],
      enviarA: map['enviarA'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      ubicacion: map['ubicacion'],
      fechaEntregaSolicitada: map['fechaEntregaSolicitada'],
      fechaEntregaProgramada: map['fechaEntregaProgramada'],
      idEstadoActual: map['idEstadoActual'],
      estado: map['estado'],
      totalAfecha: map['totalAfecha'],
      fechaAtencion: map['fechaAtencion'],
      fechaEntregado: map['fechaEntregado'],
      rutaCliente: map['rutaCliente'],
      aperturaCajaCodigo: map['aperturaCajaCodigo'],
      aperturaCajaCaja: map['aperturaCajaCaja'],
      aperturaCajaUsuario: map['aperturaCajaUsuario'],
      detallePedido: map['detallePedido'] != null ? List<DetallePedidoModel>.from(map['detallePedido'].map((x) => DetallePedidoModel.fromMap(x))) : null,
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


// PRODUCTOS
class PreciosMayoristas {
  int? idPrecioMayorista;
  String? observaciones;
  double precio;
  double minimo;
  double maximo;
  bool? estado;
  String? updatedBy;
  String? createdAt;
  String? createdBy;
  String? updatedAt;
  int? idProducto;
  bool? rangoIndefinido;

  PreciosMayoristas({
    this.idPrecioMayorista,
    this.observaciones,
    required this.precio,
    required this.minimo,
    required this.maximo,
    this.estado,
    this.updatedBy,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.idProducto,
    this.rangoIndefinido,
  });

  Map<String, dynamic> toMap() {
    return {
      'idPrecioMayorista': idPrecioMayorista,
      'observaciones': observaciones,
      'precio': precio,
      'minimo': minimo,
      'maximo': maximo,
      'estado': estado,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'idProducto': idProducto,
      'rangoIndefinido': rangoIndefinido
    };
  }

  factory PreciosMayoristas.fromMap(Map<String, dynamic> map) {
    return PreciosMayoristas(
      idPrecioMayorista: map['idPrecioMayorista'],
      observaciones: map['observaciones'],
      precio: map['precio'].toDouble(),
      minimo: map['minimo'].toDouble(),
      maximo: map['maximo'].toDouble(),
      estado: map['estado'],
      updatedBy: map['updatedBy'],
      createdAt: map['createdAt'],
      createdBy: map['createdBy'],
      updatedAt: map['updatedAt'],
      idProducto: map['idProducto'],
      rangoIndefinido: map['rangoIndefinido'],
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
  bool esMayorista;
  String? imagen;
  String? observaciones;
  String? tipoProducto;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;
  List<PreciosMayoristas>? precioMayorista;

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
    required this.esMayorista,
    this.imagen,
    this.observaciones,
    this.tipoProducto,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
    this.precioMayorista,
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
      'esMayorista': esMayorista,
      'imagen': imagen,
      'observaciones': observaciones,
      'tipoProducto': tipoProducto,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
      'precioMayorista': precioMayorista?.map((x) => x.toMap()).toList(),
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
      esMayorista: map['esMayorista'],
      imagen: map['imagen'],
      observaciones: map['observaciones'],
      tipoProducto: map['tipoProducto'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'] == 0 ? true : false,
      precioMayorista: map['precioMayorista'] != null ? List<PreciosMayoristas>.from(map['precioMayorista'].map((x) => PreciosMayoristas.fromMap(x))) : null,
    );
  }
}





// "idDireccion": 6,
// "nombre": "Principal",
// "direccionIngresada": "ESTA ES LA DIRECCION LEO QUE VA EN LA FACTURA",
// "observaciones": null,
// "idDepartamento": 10,
// "departamento": "Managua",
// "idMunicipio": 71,
// "municipio": "Managua",
// "esDirFacturacion": true,
// "googleMapsURL": "",
// "googleMapsDireccionFormated": null,
// "latitude": null,
// "longitude": null

// CLIENTES
class DireccionesClientes {
  int? idDireccion;
  String? nombre;
  String? direccionIngresada;
  String? observaciones;
  int? idDepartamento;
  String? departamento;
  int? idMunicipio;
  String? municipio;
  bool? esDirFacturacion;
  String? googleMapsURL;
  String? googleMapsDireccionFormated;
  double? latitude;
  double? longitude;

  DireccionesClientes({
    this.idDireccion,
    this.nombre,
    this.direccionIngresada,
    this.observaciones,
    this.idDepartamento,
    this.departamento,
    this.idMunicipio,
    this.municipio,
    this.esDirFacturacion,
    this.googleMapsURL,
    this.googleMapsDireccionFormated,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'idDireccion': idDireccion,
      'nombre': nombre,
      'direccionIngresada': direccionIngresada,
      'observaciones': observaciones,
      'idDepartamento': idDepartamento,
      'departamento': departamento,
      'idMunicipio': idMunicipio,
      'municipio': municipio,
      'esDirFacturacion': esDirFacturacion,
      'googleMapsURL': googleMapsURL,
      'googleMapsDireccionFormated': googleMapsDireccionFormated,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory DireccionesClientes.fromMap(Map<String, dynamic> map) {
    return DireccionesClientes(
      idDireccion: map['idDireccion'],
      nombre: map['nombre'],
      direccionIngresada: map['direccionIngresada'],
      observaciones: map['observaciones'],
      idDepartamento: map['idDepartamento'],
      departamento: map['departamento'],
      idMunicipio: map['idMunicipio'],
      municipio: map['municipio'],
      esDirFacturacion: map['esDirFacturacion'],
      googleMapsURL: map['googleMapsURL'],
      googleMapsDireccionFormated: map['googleMapsDireccionFormated'],
      latitude: map['latitude'],
      longitude: map['longitude'],
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
  String nombre;
  String? direccion;
  String? telefono;
  String? departamento;
  String? municipio;
  bool? personaNatural;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;
  List<DireccionesClientes>? direcciones;


  ClienteModel({
    this.idCliente,
    this.idCategoriaCliente,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.departamento,
    this.municipio,
    this.personaNatural,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado,
    this.direcciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCliente': idCliente,
      'idCategoriaCliente': idCategoriaCliente,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'departamento': departamento,
      'municipio': municipio,
      'personaNatural': personaNatural,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
      'direcciones': direcciones?.map((x) => x.toMap()).toList(),
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      idCliente: map['idCliente'],
      idCategoriaCliente: map['idCategoriaCliente'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      departamento: map['departamento'],
      municipio: map['municipio'],
      personaNatural: map['personaNatural'] == 0 ? true : false,
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado'] == 0 ? true : false,
      direcciones: map['direcciones'] != null ? List<DireccionesClientes>.from(map['direcciones'].map((x) => DireccionesClientes.fromMap(x))) : null,
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
      'estado': estado == true ? 0 : 1,
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
  String? nombre;
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
    this.nombre,
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
      'nombre': nombre,
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
      idVenta: map['idVenta'] is int ? map['idVenta'] as int : int.tryParse(map['idVenta']?.toString() ?? ''),
      nombre: map['nombre']?.toString(),
      noVenta: map['noVenta']?.toString(),
      idCliente: map['idCliente'] is int ? map['idCliente'] as int : int.tryParse(map['idCliente']?.toString() ?? ''),
      cliente: map['cliente']?.toString(),
      credito: (map['credito'] is bool)
          ? map['credito'] as bool
          : (map['credito'] == 1), // maneja 0/1 de SQLite o true/false de API
      observaciones: map['observaciones']?.toString(),
      enviarA: map['enviarA']?.toString(),
      ubicacion: map['ubicacion']?.toString(),
      sincronizada: (map['sincronizada'] is bool)
          ? map['sincronizada'] as bool
          : (map['sincronizada'] == 1), // default false si null
      fechaRegistro: map['fechaRegistro']?.toString(),
      usuarioRegistro: map['usuarioRegistro']?.toString(),
      estado: (map['estado'] is bool)
          ? map['estado'] as bool
          : (map['estado'] == 1), // default true si null
      total: (map['total'] is num) ? (map['total'] as num).toDouble() : null,
    );
  }
}


class DetalleVentaRapidaModel {
  int? idProducto;
  int? cantidad;
  String? usuarioRegistro;
  double? costoUnitario;
  String? observaciones;

  DetalleVentaRapidaModel({
    this.idProducto,
    this.cantidad,
    this.usuarioRegistro,
    this.costoUnitario,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProducto': idProducto,
      'cantidad': cantidad,
      'usuarioRegistro': usuarioRegistro,
      'costoUnitario': costoUnitario,
      'observaciones': observaciones,
    };
  }

  factory DetalleVentaRapidaModel.fromMap(Map<String, dynamic> map) {
    return DetalleVentaRapidaModel(
      idProducto: map['idProducto'],
      cantidad: map['cantidad'],
      usuarioRegistro: map['usuarioRegistro'],
      costoUnitario: (map['costoUnitario'] as num).toDouble(),
      observaciones: map['observaciones'],
    );
  }
}

class VentaRapidaModel {
  int? idVentaRapida;
  int? idAperturaCaja;
  String? ubicacion;
  String? usuarioRegistro;
  List<DetalleVentaRapidaModel>? detalleVenta;

  VentaRapidaModel({
    this.idVentaRapida,
    this.idAperturaCaja,
    this.ubicacion,
    this.usuarioRegistro,
    this.detalleVenta,
  });

  Map<String, dynamic> toMap() {
    return {
      'idVentaRapida': idVentaRapida,
      'idAperturaCaja': idAperturaCaja,
      'ubicacion': ubicacion,
      'usuarioRegistro': usuarioRegistro,
      'detalleVenta': detalleVenta?.map((x) => x.toMap()).toList(),
    };
  }

  factory VentaRapidaModel.fromMap(Map<String, dynamic> map) {
    return VentaRapidaModel(
        idVentaRapida: map['idVentaRapida'],
        idAperturaCaja: map['idAperturaCaja'],
        ubicacion: map['ubicacion'],
        usuarioRegistro: map['usuarioRegistro'],
        detalleVenta: map['detalleVenta'] != null ? List<DetalleVentaRapidaModel>.from(map['detalleVenta'].map((x) => DetalleVentaRapidaModel.fromMap(x))) : null,
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
      precioUnitario: (map['precioUnitario'] as num).toDouble(),
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

  TipoProductoModel fromMap(Map<String, dynamic> item) {
    return TipoProductoModel(
      idTipoProducto: item['idTipoProducto'],
      nombre: item['nombre'],
    );
  }
}



class TokenPayload {
  String aud;
  int exp;
  String idusuario;
  String iss;
  String rol;
  String permisos;
  String usuario;
  String ventanasAcceso;

  TokenPayload({
    required this.aud,
    required this.exp,
    required this.idusuario,
    required this.iss,
    required this.rol,
    required this.permisos,
    required this.usuario,
    required this.ventanasAcceso,
  });

  Map<String, dynamic> toMap() {
    return {
      'aud': aud,
      'exp': exp,
      'idusuario': idusuario,
      'iss': iss,
      'rol': rol,
      'permisos': permisos,
      'usuario': usuario,
      'ventanasAcceso': ventanasAcceso,
    };
  }

  factory TokenPayload.fromMap(Map<String, dynamic> map) {
    return TokenPayload(
      aud: map['aud'],
      exp: map['exp'],
      idusuario: map['idusuario'],
      iss: map['iss'],
      rol: map['rol'],
      permisos: map['permisos'],
      usuario: map['usuario'],
      ventanasAcceso: map['ventanasAcceso'],
    );
  }
}

class ClienteCredito {
  int? idCliente;
  String? nombre;
  bool? esTieneCredito;
  bool? esCreditoMensual;
  int? diasCredito;
  bool? esCreditoIlimitado;
  double limiteCredito;
  double creditoUsado;
  double creditoDisponible;
  int? cuentasPorCobrarPendientes;
  String? mensaje;

  ClienteCredito({
    this.idCliente,
    this.nombre,
    this.esTieneCredito,
    this.esCreditoMensual,
    this.diasCredito,
    this.esCreditoIlimitado,
    required this.limiteCredito,
    required this.creditoUsado,
    required this.creditoDisponible,
    this.cuentasPorCobrarPendientes,
    this.mensaje
  });

  Map<String, dynamic> toMap() {
    return {
      'idCliente': idCliente,
      'nombre': nombre,
      'esTieneCredito': esTieneCredito,
      'esCreditoMensual': esCreditoMensual,
      'diasCredito': diasCredito,
      'esCreditoIlimitado': esCreditoIlimitado,
      'limiteCredito': limiteCredito,
      'creditoUsado': creditoUsado,
      'creditoDisponible': creditoDisponible,
      'cuentasPorCobrarPendientes': cuentasPorCobrarPendientes,
      'mensaje': mensaje,
    };
  }


  factory ClienteCredito.fromMap(Map<String, dynamic> map) {
    return ClienteCredito(
      idCliente: map['idCliente'],
      nombre: map['nombre'],
      esTieneCredito: map['esTieneCredito'],
      esCreditoMensual: map['esCreditoMensual'],
      diasCredito: map['diasCredito'],
      esCreditoIlimitado: map['esCreditoIlimitado'],
      limiteCredito:
      (map['limiteCredito'] as num).toDouble(),

      creditoUsado:
      (map['creditoUsado'] as num).toDouble(),

      creditoDisponible:
      (map['creditoDisponible'] as num).toDouble(),
      cuentasPorCobrarPendientes: map['cuentasPorCobrarPendientes'],
      mensaje: map['mensaje']
    );
  }
}


// RETIRO MODELS
// {
// "idRetiroCaja": 1,
// "idAperturaCaja": 9,
// "aperturaCodigo": "APE-C01-9",
// "idConcepto": 1027,
// "conceptoNombre": "Pago de estacionamiento",
// "monto": 0.01,
// "observaciones": "string",
// "fechaRegistro": "2026-09-12T01:20:48.557",
// "usuarioRegistro": "SoporteDevoD",
// "estado": true
// }

class RetiroEfectivoModel {
  int? idRetiroCaja;
  int? idAperturaCaja;
  String? aperturaCodigo;
  int? idConcepto;
  String? conceptoNombre;
  double? monto;
  String? observaciones;
  String? fechaRegistro;
  String? usuarioRegistro;
  bool? estado;

  RetiroEfectivoModel({
    this.idRetiroCaja,
    this.idAperturaCaja,
    this.aperturaCodigo,
    this.idConcepto,
    this.conceptoNombre,
    this.monto,
    this.observaciones,
    this.fechaRegistro,
    this.usuarioRegistro,
    this.estado
  });

  Map<String, dynamic> toMap() {
    return {
      'idRetiroCaja': idRetiroCaja,
      'idAperturaCaja': idAperturaCaja,
      'aperturaCodigo': aperturaCodigo,
      'idConcepto': idConcepto,
      'conceptoNombre': conceptoNombre,
      'monto': monto,
      'observaciones': observaciones,
      'fechaRegistro': fechaRegistro,
      'usuarioRegistro': usuarioRegistro,
      'estado': estado,
    };
  }

  factory RetiroEfectivoModel.fromMap(Map<String, dynamic> map) {
    return RetiroEfectivoModel(
      idRetiroCaja: map['idRetiroCaja'],
      idAperturaCaja: map['idAperturaCaja'],
      aperturaCodigo: map['aperturaCodigo'],
      idConcepto: map['idConcepto'],
      conceptoNombre: map['conceptoNombre'],
      monto: map['monto'],
      observaciones: map['observaciones'],
      fechaRegistro: map['fechaRegistro'],
      usuarioRegistro: map['usuarioRegistro'],
      estado: map['estado']
    );
  }
}