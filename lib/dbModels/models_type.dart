class CajaModel {
  final int idCaja;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int idEstadoActual;
  final String estadoActual;
  final int idBodega;
  final String bodega;

  CajaModel({
    required this.idCaja,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.idEstadoActual,
    required this.estadoActual,
    required this.idBodega,
    required this.bodega,
  });

  factory CajaModel.fromJson(Map<String, dynamic> json) {
    return CajaModel(
      idCaja: json['idCaja'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      idEstadoActual: json['idEstadoActual'],
      estadoActual: json['estadoActual'],
      idBodega: json['idBodega'],
      bodega: json['bodega'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCaja': idCaja,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'idEstadoActual': idEstadoActual,
      'estadoActual': estadoActual,
      'idBodega': idBodega,
      'bodega': bodega,
    };
  }
}