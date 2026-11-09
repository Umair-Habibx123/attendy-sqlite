import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class UserDBHelper {
  static final UserDBHelper instance = UserDBHelper._init();
  static Database? _database;

  UserDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const blobType = 'BLOB';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        email $textType UNIQUE,
        password $textType,
        profilePicture $blobType,
        role $textType
      )
    ''');
  }

  Future<int> insertUser({
    required String username,
    required String email,
    required String password,
    Uint8List? profilePicture,
    required String role,
  }) async {
    final db = await database;

    final values = {
      'username': username,
      'email': email,
      'password': password,
      'profilePicture': profilePicture,
      'role': role,
    };

    return await db.insert('users', values);
  }

  Future<int> updateUser({
    required String username,
    required String password,
    Uint8List? profilePicture,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception('Email not found in SharedPreferences');
    }

    final db = await database;

    final values = <String, dynamic>{
      'username': username,
      'password': password,
    };

    if (profilePicture != null) {
      values['profilePicture'] = profilePicture;
    }

    return await db.update(
      'users',
      values,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    return result.isNotEmpty ? result.first : null;
  }


  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<List<String>> getUsernamesWithRoleUser() async {
  final db = await database;
  final result = await db.query(
    'users',
    columns: ['username'],
    where: 'role = ?',
    whereArgs: ['user'],
    orderBy: 'username ASC', 
  );

  List<String> usernames = result.isNotEmpty
      ? result.map((user) => user['username'] as String).toList()
      : [];

  return usernames;
}


Future<String?> deleteUserByUsername(String username) async {
  final db = await database;
  
 
  final result = await db.query(
    'users',
    columns: ['email'],
    where: 'username = ?',
    whereArgs: [username],
  );

  if (result.isNotEmpty) {
    String email = result.first['email'] as String;
    
   
    await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
  
    return email;
  } else {
    return null; 
  }
}


Future<String?> getEmailByUsername(String username) async {
  final db = await database;
  final result = await db.query(
    'users',
    columns: ['email'],
    where: 'username = ?',
    whereArgs: [username],
  );

  if (result.isNotEmpty) {
    return result.first['email'] as String;
  } else {
    return null;
  }
}

Future<Map<String, dynamic>?> getUserDetailsByUsername(String username) async {
  final db = await database;
  final result = await db.query(
    'users',
    columns: ['username', 'email', 'profilePicture'],
    where: 'username = ?',
    whereArgs: [username],
  );

  if (result.isNotEmpty) {
    return {
      'username': result.first['username'] as String,
      'email': result.first['email'] as String,
      'profilePicture': result.first['profilePicture'] as Uint8List?,
    };
  } else {
    return null;
  }
}


}

