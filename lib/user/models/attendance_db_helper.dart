import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceDBHelper {
  static final AttendanceDBHelper instance = AttendanceDBHelper._init();
  static Database? _database;

  AttendanceDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendance.db');
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
      CREATE TABLE attendance (
        id $idType,
        email $textType,
        date TEXT NOT NULL, -- Use date instead of datetime for date-only storage
        status $textType
      )
    ''');
  }

  Future<int> insertAttendance(String email, String date, String status) async {
    final db = await database;
    final values = {
      'email': email,
      'date': date,
      'status': status,
    };

    return await db.insert('attendance', values);
  }

Future<bool> insertAttendanceRange(String email, String fromDate, String toDate, String status) async {
  final db = await database;
 
  var batch = db.batch();

  
  DateTime startDate = DateTime.parse(fromDate);
  DateTime endDate = DateTime.parse(toDate);
  int differenceInDays = endDate.difference(startDate).inDays;

  bool inserted = false; 

 
  for (int i = 0; i <= differenceInDays; i++) {
    DateTime currentDate = startDate.add(Duration(days: i));
    String currentDateFormatted = DateFormat('yyyy-MM-dd').format(currentDate);

    
    List<Map<String, dynamic>> existingRecords = await db.query(
      'Attendance',
      where: 'email = ? AND date = ?',
      whereArgs: [email, currentDateFormatted],
    );

    if (existingRecords.isEmpty) {
      batch.insert('Attendance', {'email': email, 'date': currentDateFormatted, 'status': status});
      inserted = true;  
    } else {
      
    }
  }

  
  await batch.commit();
  
  
  return inserted;
}



Future<bool> deleteAttendanceRange(String email, String fromDate, String toDate) async {
  final db = await database;
   
  var batch = db.batch();
 
  DateTime startDate = DateTime.parse(fromDate);
  DateTime endDate = DateTime.parse(toDate);
  int differenceInDays = endDate.difference(startDate).inDays;

  bool deleted = false;  
 
  for (int i = 0; i <= differenceInDays; i++) {
    DateTime currentDate = startDate.add(Duration(days: i));
    String currentDateFormatted = DateFormat('yyyy-MM-dd').format(currentDate);

   
    int rowsDeleted = await db.delete('Attendance', where: 'email = ? AND date = ?', whereArgs: [email, currentDateFormatted]);

    if (rowsDeleted > 0) {
      deleted = true; 
    }
  }

 
  await batch.commit();

  return deleted; 
}





Future<List<Map<String, dynamic>>> getAttendanceRecords(String email) async {
  final db = await database;
  return await db.query(
    'attendance',
    where: 'email = ?',
    whereArgs: [email],
    orderBy: 'date ASC', // Sort by date in ascending order
  );
}


 Future<List<Map<String, dynamic>>> getAttendanceRecordsRange(String email, String startDate, String endDate) async {
  final db = await database;
  return await db.query(
    'attendance',
    where: 'email = ? AND date >= ? AND date <= ?',
    whereArgs: [email, startDate, endDate],
    orderBy: 'date ASC', // Sort by date in ascending order
  );
}

Future<bool> checkAttendanceRecordsRange(String email, String startDate, String endDate) async {
  final db = await database;

  // Calculate the total number of days in the date range
  DateTime start = DateTime.parse(startDate);
  DateTime end = DateTime.parse(endDate);
  int totalDays = end.difference(start).inDays + 1;

  // Retrieve the count of attendance records within the date range
  List<Map<String, dynamic>> countResult = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM attendance
    WHERE email = ? AND date >= ? AND date <= ?
  ''', [email, startDate, endDate]);

  int recordCount = countResult.isNotEmpty ? countResult.first['count'] as int : 0;

  // Return true if every day within the range has an entry, otherwise false
  return recordCount == totalDays;
}






  Future<bool> getTodayAttendance(String email) async {
    final db = await database;
    final today = DateTime.now();
    final todayStr =
        DateFormat('yyyy-MM-dd').format(today); // Format for date-only

    final result = await db.query(
      'attendance',
      where: 'email = ? AND date = ?',
      whereArgs: [email, todayStr],
    );

    return result.isNotEmpty;
  }

  Future<void> markAttendanceAsAbsent(String email) async {
    final currentTime = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(currentTime);

    // Check if attendance for today exists
    final todayAttendance = await getTodayAttendance(email);

    if (!todayAttendance) {
      // Insert new attendance record as absent
      await insertAttendance(email, formattedDate, 'absent');
    } else {
      // Attendance already marked for today
      throw Exception('Attendance already marked for today.');
    }
  }

 Future<bool> updateAttendanceStatus(String email, String date, String status) async {
  final db = await database;
  final values = {
    'status': status,
  };

  int rowsAffected = await db.update(
    'attendance',
    values,
    where: 'email = ? AND date = ?',
    whereArgs: [email, date],
  );

  return rowsAffected > 0; // Return true if rows were updated, false otherwise
}



  Future<void> markAttendance(String email) async {
    final currentTime = DateTime.now();
    final formattedDate =
        DateFormat('yyyy-MM-dd').format(currentTime); // Extract date only

    // Check if attendance for today exists
    bool todayAttendance = await getTodayAttendance(email);

    if (!todayAttendance) {
      // Insert new attendance record
      await insertAttendance(email, formattedDate, 'present');
    } else {
      // Attendance already marked for today
      throw Exception('Attendance already marked for today.');
    }
  }

   Future<void> markLeave(String email) async {
    final currentTime = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(currentTime);

    // Check if attendance for today exists
    bool todayAttendance = await getTodayAttendance(email);

    if (!todayAttendance) {
      // Insert new leave record
      await insertAttendance(email, formattedDate, 'On Leave');
    } else {
      // Attendance already marked for today
      throw Exception('Attendance already marked for today.');
    }
  }

   Future<int> totalPresentCount(String email, String startDate, String endDate) async {
    try {
      final Database db = await instance.database;
      List<Map<String, dynamic>> countResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM attendance
        WHERE email = ? AND date BETWEEN ? AND ? AND status = 'present'
      ''', [email, startDate, endDate]);

      int totalCount = countResult.isNotEmpty ? countResult.first['count'] as int : 0;
      return totalCount;
    } catch (e) {
      print('Error calculating total present count: $e');
      throw Exception('Failed to get total present count');
    }
  }
  

   Future<int> totalAbsentCount(String email, String startDate, String endDate) async {
    try {
      final Database db = await instance.database;
      List<Map<String, dynamic>> countResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM attendance
        WHERE email = ? AND date BETWEEN ? AND ? AND status = 'absent'
      ''', [email, startDate, endDate]);

      int totalCount = countResult.isNotEmpty ? countResult.first['count'] as int : 0;
      return totalCount;
    } catch (e) {
      print('Error calculating total present count: $e');
      throw Exception('Failed to get total present count');
    }
  }
   Future<int> totalLeaveCount(String email, String startDate, String endDate) async {
    try {
      final Database db = await instance.database;
      List<Map<String, dynamic>> countResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM attendance
        WHERE email = ? AND date BETWEEN ? AND ? AND status = 'On Leave'
      ''', [email, startDate, endDate]);

      int totalCount = countResult.isNotEmpty ? countResult.first['count'] as int : 0;
      return totalCount;
    } catch (e) {
      print('Error calculating total present count: $e');
      throw Exception('Failed to get total present count');
    }
  }


  Future<int> deleteUserAttendanceByEmail(String? email) async {
    final db = await database;
    return await db.delete(
      'attendance',
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
