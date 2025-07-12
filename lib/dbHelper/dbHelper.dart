import 'package:inversiones_ar/dbModels/dbModels.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();
  static Database? _database;

  DbHelper._();

  factory DbHelper() => _instance;

  Future<Database> get database async {
    if (_database!.isOpen) return _database!;
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
          usuarioRegistro INTEGER NOT NULL, -- bigint se mapea a INTEGER
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
          usuarioRegistro INTEGER NOT NULL, -- bigint se mapea a INTEGER
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
          credito INTEGER NOT NULL,
          observaciones TEXT,
          enviarA TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
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
          estado BOOLEAN NOT NULL,
          FOREIGN KEY (idVenta) REFERENCES Venta (idVenta) ON DELETE CASCADE,
          FOREIGN KEY (idProducto) REFERENCES Producto (idProducto) ON DELETE CASCADE
        )
    ''');

        // HASTA AQUI LOS MODELOS DE LA BASE DE DATOS
        await db.execute('''
        CREATE TABLE DetalleCompra (
          idDetalleCompra INTEGER PRIMARY KEY AUTOINCREMENT,
          idCompra INTEGER NOT NULL,
          idProducto INTEGER NOT NULL,
          cantidad REAL NOT NULL,
          costoUnitario REAL NOT NULL,
          observaciones TEXT,
          FOREIGN KEY (IdCompra) REFERENCES Compra (IdCompra) ON DELETE CASCADE,
          FOREIGN KEY (idProducto) REFERENCES Producto (idProducto) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE Compra (
          idCompra INTEGER PRIMARY KEY AUTOINCREMENT,
          noOrden TEXT,
          idProveedor INTEGER NOT NULL,
          aprobada INTEGER NOT NULL,
          observaciones TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idProveedor) REFERENCES Proveedor (idProveedor) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE CXC (
          idCXC INTEGER PRIMARY KEY AUTOINCREMENT,
          noCXC TEXT,
          idCliente INTEGER NOT NULL,
          observaciones TEXT,
          fechaRegistro TEXT NOT NULL,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idCliente) REFERENCES Cliente (idCliente) ON DELETE CASCADE
        )
    ''');

        await db.execute('''
        CREATE TABLE DetalleCXC (
          idDetalleCXC INTEGER PRIMARY KEY AUTOINCREMENT,
          idCXC INTEGER NOT NULL,
          idVenta INTEGER NOT NULL,
          monto REAL NOT NULL,
          nCuotas INTEGER NOT NULL,
          diasCredito INTEGER NOT NULL,
          saldo REAL NOT NULL,
          cancelado INTEGER NOT NULL,
          fechaRegistro TEXT,
          usuarioRegistro TEXT NOT NULL,
          estado INTEGER NOT NULL,
          FOREIGN KEY (idCXC) REFERENCES CXC (idCXC) ON DELETE CASCADE,
          FOREIGN KEY (idVenta) REFERENCES Venta (idVenta) ON DELETE CASCADE
        )
    ''');
      },
    );
  }

  Future<List<ProductoModel>> getProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query("Producto");

    return maps.map((map) => ProductoModel.fromMap(map)).toList();
  }

  Future<List<VentaModel>> getVentas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Ventas');

    return maps.map((map) => VentaModel.fromMap(map)).toList();
  }

  Future<List<DetalleVentaModel>> getDetalleVentas(int idVenta) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        'DetalleVentas',
      where: 'idVenta = ?',
      whereArgs: [idVenta]
    );

    return maps.map((map) => DetalleVentaModel.fromMap(map)).toList();
  }

  Future<int> insertVenta(VentaModel venta) async {
    final db = await database;
    return await db.insert('Ventas',
        venta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }
}
