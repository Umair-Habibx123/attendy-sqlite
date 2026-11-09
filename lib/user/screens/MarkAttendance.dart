import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';

class AttendanceButton extends StatefulWidget {
  const AttendanceButton({super.key});

  @override
  _AttendanceButtonState createState() => _AttendanceButtonState();
}

class _AttendanceButtonState extends State<AttendanceButton> {
  bool _isButtonEnabled = true;
  AttendanceDBHelper attendanceDBHelper = AttendanceDBHelper.instance;
  String? _email;

  @override
  void initState() {
    super.initState();
    _messageForMarkAttendance();
  }

  Future<void> _messageForMarkAttendance() async {
    if (_isButtonEnabled = true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance can only be marked between 8 AM and 1 PM.'),
        ),
      );
    }
  }

  Future<void> _updateAttendanceStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _email = prefs.getString('email');
      await AttendanceDBHelper.instance.markAttendance(_email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked as present.')),
      );
      setState(() {
        _isButtonEnabled = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isButtonEnabled ? _updateAttendanceStatus : null,
          child: const Text('Mark Attendance'),
        ),
      ),
    );
  }
}
