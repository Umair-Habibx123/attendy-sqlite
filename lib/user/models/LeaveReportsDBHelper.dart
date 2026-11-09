import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LeaveReportsDBHelper {
  static final LeaveReportsDBHelper instance = LeaveReportsDBHelper._init();
  static Database? _database;

  LeaveReportsDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('leave.db');
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

    await db.execute('''
      CREATE TABLE leave(
        id $idType,
        username $textType,
        email $textType,
        date TEXT NOT NULL,
        leave $textType
      )
    ''');
  }

  Future<int> insertLeaveReport(String username,String email, String date, String leave) async {
    final db = await database;
    final values = {
      'username': username,
      'email': email,
      'date': date,
      'leave': leave,
    };

    return await db.insert('leave', values);
  }


  Future<void> leaveApplication(String username, String email, String leave) async {
    final currentTime = DateTime.now();
    final formattedDate =
        DateFormat('yyyy-MM-dd').format(currentTime);  
   
    bool todayAttendance = await getTodayAttendance(email);

    if (!todayAttendance) {
     
      await insertLeaveReport(username, email, formattedDate, leave);
    } else {
   
      throw Exception('Attendance already marked for today.');
    }
  }

  Future<bool> getTodayAttendance(String email) async {
     final db = await database;
    final today = DateTime.now();
    final todayStr =
        DateFormat('yyyy-MM-dd').format(today); 
    final result = await db.query(
      'leave',
      where: 'email = ? AND date = ?',
      whereArgs: [email, todayStr],
    );

    return result.isNotEmpty;
  }

  

  Future<int> deleteUserLeaveByEmail(String? email) async {
    final db = await database;
  return await db.delete(
    'leave',
    where: 'email = ?',
    whereArgs: [email],
  );
  }


  Future<String> sendLeaveApplication(String username, String email, String date) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> countResult = await db.rawQuery('''
        SELECT leave
        FROM leave
        WHERE username = ? AND email = ? AND date = ?
      ''', [username, email, date]);

      if (countResult.isNotEmpty) {
        return countResult.first['leave'];
      } else {
        return 'No leave application found. Admin must have entered as Leave.';
      }
    } catch (e) {
      print('Error retrieving leave application: $e');
      throw Exception('Failed to retrieve leave application.');
    }
  }
}
