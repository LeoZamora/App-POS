import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart' as requests;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();
  static Database? _database;

  DbHelper._();

  factory DbHelper() => _instance;

  Future<Database> get database async {
    final db = _database;
    if (db != null && db.isOpen) return db;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inversiones_ar.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Ubicacion (
            idUbicacion INTEGER PRIMARY KEY,
            nombre TEXT NOT NULL,
            fechaRegistro TEXT NOT NULL
          )
        ''');

        await db.execute('''        
       CREATE TABLE CategoriaProducto(
          dCategoriaProducto INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL
       )''');

        await db.execute('''
        CREATE TABLE SubCategoriaProd (
          idSubCatProd INTEGER PRIMARY KEY AUTOINCREMENT,
          dCategoriaProducto INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (dCategoriaProducto) REFERENCES CategoriaProducto (dCategoriaProducto) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE UnidadMedida (
          idUnidadMedida INTEGER PRIMARY KEY AUTOINCREMENT,
          abreviatura TEXT,
          nombre TEXT NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL
        )
    ''');

        await db.execute('''
        CREATE TABLE Producto (
          idProducto INTEGER PRIMARY KEY AUTOINCREMENT,
          idSubCatProd INTEGER NOT NULL,
          idUnidadMedida INTEGER NOT NULL,
          codigo TEXT,
          nombre TEXT NOT NULL,
          precio REAL NOT NULL,
          costo REAL NOT NULL,
          cantidadTotal REAL NOT NULL,
          cantidadMinima REAL NOT NULL,
          imagen BLOB,
          observaciones TEXT,
          tipoProducto TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idSubCatProd) REFERENCES SubCategoriaProd (idSubCatProd) ON DELETE CASCADE,
          FOREIGN KEY (idUnidadMedida) REFERENCES UnidadMedida (idUnidadMedida) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE CategoriaCliente (
          idCategoriaCliente INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL
        )
    ''');

        await db.execute('''
        CREATE TABLE Cliente (
          idCliente INTEGER PRIMARY KEY AUTOINCREMENT,
          idCategoriaCliente INTEGER NOT NULL,
          codigo TEXT,
          direccion TEXT,
          telefono TEXT,
          departamento TEXT,
          municipio TEXT,
          personaNatural INTEGER NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL, -- Cambiado de datetime a TEXT para consistencia
          estado INTEGER NOT NULL,
          FOREIGN KEY (idCategoriaCliente) REFERENCES CategoriaCliente (idCategoriaCliente) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE TipoProveedor (
          idTipoProveedor INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          observaciones TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL
        )
    ''');

        await db.execute('''
        CREATE TABLE Proveedor (
          idProveedor INTEGER PRIMARY KEY AUTOINCREMENT,
          idTipoProveedor INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          departamento TEXT,
          municipio TEXT,
          direccion TEXT,
          telefono TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idTipoProveedor) REFERENCES TipoProveedor (idTipoProveedor) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE ProveedorProducto (
          idProveedorProducto INTEGER PRIMARY KEY AUTOINCREMENT,
          idProveedor INTEGER NOT NULL,
          idProducto INTEGER NOT NULL,
          observaciones TEXT,
          predeterminado INTEGER NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idProveedor) REFERENCES Proveedor (idProveedor) ON DELETE CASCADE,
          FOREIGN KEY (idProducto) REFERENCES Producto (idProducto) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE Venta (
          idVenta INTEGER PRIMARY KEY AUTOINCREMENT,
          noVenta TEXT,
          idCliente INTEGER NOT NULL,
          cliente TEXT NOT NULL,
          credito INTEGER NOT NULL,
          observaciones TEXT,
          enviarA TEXT,
          ubicacion TEXT,
          sincronizada INTEGER NOT NULL,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          total REAL,
          FOREIGN KEY (idCliente) REFERENCES Cliente (idCliente) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE DetalleVenta (
          idDetalleVenta INTEGER PRIMARY KEY AUTOINCREMENT,
          idVenta INTEGER NOT NULL,
          idProducto INTEGER NOT NULL,
          cantidad REAL NOT NULL,
          precioUnitario REAL NOT NULL,
          observaciones TEXT,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idVenta) REFERENCES Venta (idVenta) ON DELETE CASCADE,
          FOREIGN KEY (idProducto) REFERENCES Producto (idProducto) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE TipoProducto (
          idTipoProducto INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL
        )
        ''');

        await db.insert('TipoProducto', {'nombre': 'Herramientas'});

        await db.execute('''
        CREATE TABLE NumeroConsecutivoVenta(
          idNumero INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          noVenta INTEGER
        )
        ''');
      },
    );
  }

  Future<List<ProductoModel>> getProductos(String tipoProducto) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query("Producto",
        where: 'tipoProducto = ?', whereArgs: [tipoProducto]
    );
    return maps.map((map) {
      final mappedData = Map<String, dynamic>.from(map);
      mappedData['estado'] = map['estado'] == 1 ? true : false;
      return ProductoModel.fromMap(mappedData);
    }).toList();
  }

  Future<List<DetalleVentaModel>> getDetalleVentas(int idVenta) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        'DetalleVenta',
      where: 'idVenta = ?',
      whereArgs: [idVenta]
    );
    return maps.map((map) => DetalleVentaModel.fromMap(map)).toList();
  }

  Future<void> registrarVenta(VentaModel venta, List<DetalleVentaModel> detalles) async {
    final db = await database;
    
    db.transaction((txn) async {
      int idVenta = await txn.insert('Venta', {
        'noVenta': venta.noVenta,
        'idCliente': venta.idCliente,
        'cliente': venta.cliente,
        'credito': venta.credito == true ? 1 : 0,
        'observaciones': venta.observaciones,
        'sincronizada': venta.sincronizada == true ? 1 : 0,
        'enviarA': venta.enviarA,
        'ubicacion': venta.ubicacion,
        'fechaRegistro': venta.fechaRegistro,
        'usuarioRegistro': venta.usuarioRegistro,
        'estado':  1,
        'total': venta.total
      });
      
      for(var detalle in detalles) {
        await txn.insert('DetalleVenta', {
          'idVenta': idVenta,
          'idProducto': detalle.idProducto,
          'cantidad': detalle.cantidad,
          'precioUnitario': detalle.precioUnitario,
          'observaciones': detalle.observaciones,
          'estado': 1
        });

        await txn.update(
          'Producto',
          {'cantidadTotal': detalle.cantidad},
          where: 'idProducto = ?',
          whereArgs: [detalle.idProducto],
        );
      }
    });
  }

  Future<List<VentaModel>> getVentas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Venta', orderBy: 'idVenta DESC');
    return maps.map((map) {
      final mappedData = Map<String, dynamic>.from(map);
      mappedData['credito'] = map['credito'] == 1 ? true : false;
      mappedData['sincronizada'] = map['sincronizada'] == 1 ? true : false;
      mappedData['estado'] = map['estado'] == 1 ? true : false;
      return VentaModel.fromMap(mappedData);
    }).toList();
  }

  Future<List<ClienteModel>> getClientesLocal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Cliente');
    return maps.map((map) {
      final mappedData = Map<String, dynamic>.from(map);
      mappedData['personaNatural'] = map['personaNatural'] == 1 ? true : false;
      mappedData['estado'] = map['estado'] == 1 ? true : false;
      return ClienteModel.fromMap(mappedData);
    }).toList();
  }

  Future<List<TipoProductoModel>> insertTipoProducto(List<TipoProductoModel> tipoProducto) async {
    final db = await database;

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM TipoProducto'),
    );

    if(count == 0) {
      for(var tipo in tipoProducto) {
        await db.insert('TipoProducto', tipo.toMap());
      }
    }

    final List<Map<String, dynamic>> maps = await db.query('TipoProducto');
    return maps.map((map) => TipoProductoModel.fromMap(map)).toList();
  }

  Future<void> deleteTipoProducto() async {
    final db = await database;

    await db.delete('TipoProducto');
    print('Delete All');
  }

  Future<List<TipoProductoModel>> getTipoProducto() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('TipoProducto');

    return maps.map((map) => TipoProductoModel.fromMap(map)).toList();
  }

  Future<bool> sincronizarProductosDesdeAPI(String tipoProducto) async {
    final db = await DbHelper().database;

    try {
      List<VentaModel> _ventas = await getVentas();
      List<Map<String, dynamic>> detalles = [];


      for(var venta in _ventas) {
        if(venta.sincronizada == false) {
          List<DetalleVentaModel> _detalles = await getDetalleVentas(venta.idVenta!);

          for(var detalle in _detalles) {
            Map<String, dynamic> detalleDet = {
              "idVenta": detalle.idVenta,
              "idProducto": detalle.idProducto,
              "cantidad": detalle.cantidad,
              "precioUnitario": detalle.precioUnitario,
              "observaciones": detalle.observaciones,
            };
            detalles.add(detalleDet);
          }

          Map<String, dynamic> ventaDet = {
            "noVenta": venta.noVenta,
            "idCliente": venta.idCliente,
            "credito": venta.credito,
            "observaciones": venta.observaciones,
            "enviarA": venta.enviarA,
            "sincronizada": venta.sincronizada,
            "usuarioRegistro": venta.usuarioRegistro,
            "detalleVenta": detalles,
          };

          await requests.postVentas(ventaDet);
          await db.update(
            'Venta',
            {'sincronizada': 1},
            where: 'idVenta = ?',
            whereArgs: [venta.idVenta],
          );
        }
      }

      final List<ClienteModel> clientesAPI = await requests.getClientes();
        for(var cliente in clientesAPI) {
          final List<Map<String, dynamic>> existentes = await db.query(
            'Cliente',
            where: 'codigo = ?',
            whereArgs: [cliente.codigo],
          );

          final clienteMap = cliente.toMap();
          print('clienteMap: ${clienteMap.toString()}');
          clienteMap['personaNatural'] = cliente.personaNatural == true ? 1 : 0;
          clienteMap['estado'] = cliente.estado == true ? 1 : 0;

          if(existentes.isEmpty) {
            print('Creados Clientes');
            await db.insert('Cliente', clienteMap);
            print('Creados');
          } else {
            print('Actualizados Clientes');
            await db.update(
              'Cliente',
                clienteMap,
              where: 'codigo = ?',
              whereArgs: [cliente.codigo],
            );
          }
        }

        final List<ProductoModel> productosAPI = await requests.getProductos(tipoProducto);
        for (final producto in productosAPI) {
          final List<Map<String, dynamic>> existentes = await db.query(
            'Producto',
            where: 'idProducto = ?',
            whereArgs: [producto.idProducto],
          );

          final productoMap = producto.toMap();
          productoMap['estado'] = producto.estado == true ? 1 : 0;

          if (existentes.isEmpty) {
            print('Creadas');
            await db.insert('Producto', productoMap);
          } else {
            print('Actualizada');
            await db.update(
              'Producto',
              productoMap,
              where: 'idProducto = ?',
              whereArgs: [producto.idProducto],
            );
          }
        }
        return true;
    } catch (e) {
      print("Error al sincronizar productos: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getUbicacion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Ubicacion');

    return maps.first;
  }

  Future<int> getNumeroSugerido() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'NumeroConsecutivoVenta',
      orderBy: 'noVenta DESC',
      limit: 1,
    );

    print('Maps: ${maps.toString()}');

    if(maps.isNotEmpty) {
      return maps.first['noVenta'] + 1 as int;
    } else {
      return 1;
    }
  }

  Future<void> insertNoVenta(int noVenta) async {
    final db = await database;
    print('Insertando número consecutivo: $noVenta');
    try {
      db.transaction((txn) async {
        txn.insert('NumeroConsecutivoVenta', {
          "noVenta": noVenta
        });
      });
    } catch (e) {
      print('Error al insertar el número consecutivo: $e');
    }
  }
}
