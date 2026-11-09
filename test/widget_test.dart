// Tests the app's SQLite helpers against a real SQLite database
// (sqflite_common_ffi runs SQLite on the desktop, so no phone is needed).
import 'dart:io';

import 'package:attendy_sqlite/shared/models/UserDBHelper.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dbDir;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbDir = await Directory.systemTemp.createTemp('attendy_sqlite_test');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  tearDownAll(() async {
    // The helpers keep their databases open; Windows can't delete open files.
    // It's a temp folder, so leaving it behind there is harmless.
    try {
      await dbDir.delete(recursive: true);
    } on FileSystemException {
      // ignore
    }
  });

  group('users', () {
    test('a registered user can log in with the right password only', () async {
      await UserDBHelper.instance.insertUser(
        username: 'ali', email: 'ali@example.com', password: 'pass1234', profilePicture: null, role: 'user');

      final user = await UserDBHelper.instance.getUser('ali@example.com', 'pass1234');
      expect(user?['username'], 'ali');
      expect(user?['role'], 'user');
      expect(await UserDBHelper.instance.getUser('ali@example.com', 'wrong'), isNull);
    });

    test('emails and usernames are unique', () async {
      await UserDBHelper.instance.insertUser(
        username: 'sara', email: 'sara@example.com', password: 'pass1234', profilePicture: null, role: 'user');
      expect(
        () => UserDBHelper.instance.insertUser(
          username: 'sara2', email: 'sara@example.com', password: 'x', profilePicture: null, role: 'user'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => UserDBHelper.instance.insertUser(
          username: 'sara', email: 'other@example.com', password: 'x', profilePicture: null, role: 'user'),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('attendance', () {
    test('attendance can be marked only once per day', () async {
      const email = 'once@example.com';
      expect(await AttendanceDBHelper.instance.getTodayAttendance(email), isFalse);
      await AttendanceDBHelper.instance.markAttendance(email);
      expect(await AttendanceDBHelper.instance.getTodayAttendance(email), isTrue);
      expect(() => AttendanceDBHelper.instance.markAttendance(email), throwsException);
      expect(() => AttendanceDBHelper.instance.markLeave(email), throwsException);
    });

    test('present, absent and leave are counted over a date range', () async {
      const email = 'counts@example.com';
      final db = AttendanceDBHelper.instance;
      await db.insertAttendance(email, '2026-01-05', 'present');
      await db.insertAttendance(email, '2026-01-06', 'present');
      await db.insertAttendance(email, '2026-01-07', 'absent');
      await db.insertAttendance(email, '2026-01-08', 'On Leave');
      await db.insertAttendance(email, '2026-02-02', 'present'); // outside the range

      expect(await db.totalPresentCount(email, '2026-01-01', '2026-01-31'), 2);
      expect(await db.totalAbsentCount(email, '2026-01-01', '2026-01-31'), 1);
      expect(await db.totalLeaveCount(email, '2026-01-01', '2026-01-31'), 1);
    });

    test('marking leave records today as "On Leave"', () async {
      const email = 'leave@example.com';
      await AttendanceDBHelper.instance.markLeave(email);
      expect(await AttendanceDBHelper.instance.totalLeaveCount(email, today, today), 1);
    });

    test("deleting a user's attendance removes all of their records", () async {
      const email = 'gone@example.com';
      await AttendanceDBHelper.instance.insertAttendance(email, '2026-03-02', 'present');
      await AttendanceDBHelper.instance.deleteUserAttendanceByEmail(email);
      expect(await AttendanceDBHelper.instance.totalPresentCount(email, '2026-01-01', '2026-12-31'), 0);
    });
  });
}
