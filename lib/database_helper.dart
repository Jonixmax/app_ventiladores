import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "UsuariosIot.db";
  static const _databaseVersion = 1;
  
  static const table = 'usuarios';
  static const columnId = 'id';
  static const columnNombre = 'nombre';
  static const columnRol = 'rol'; 
  static const columnPin = 'pin'; 

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  
  get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    var path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnNombre TEXT NOT NULL,
        $columnRol TEXT NOT NULL,
        $columnPin TEXT NOT NULL
      )
      ''');
    
    await db.insert(table, {
      columnNombre: 'Administrador Principal',
      columnRol: 'admin',
      columnPin: '1234'
    });
  }

  insert(Map row) async {
    Database db = await instance.database;
    // Truco: Transformamos el mapa para evitar errores de tipo sin usar los símbolos
    var filaSegura = { for (var e in row.entries) e.key.toString(): e.value };
    return await db.insert(table, filaSegura);
  }

  queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}