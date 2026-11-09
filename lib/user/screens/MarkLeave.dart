import 'package:attendy_sqlite/user/models/LeaveReportsDBHelper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';

class MarkLeaveScreen extends StatefulWidget {
  const MarkLeaveScreen({super.key});

  @override
  _MarkLeaveScreenState createState() => _MarkLeaveScreenState();
}

class _MarkLeaveScreenState extends State<MarkLeaveScreen> {
  bool _isButtonEnabled = true;
  AttendanceDBHelper attendanceDBHelper = AttendanceDBHelper.instance;
  String? _email;
  String? _username;
  var leaveRequest = '';

  @override
  void initState() {
    super.initState();
    _messageForMarkLeave();
  }

  Future<void> _messageForMarkLeave() async {
    if (_isButtonEnabled = true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave can only be sent between 8 AM and 1 PM.'),
        ),
      );
    }
  }

  Future<void> _updateLeaveStatus() async {
    try {
      if (leaveRequest.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter leave request')),
        );
        return;
      }
      else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        _email = prefs.getString('email');
        _username = prefs.getString('username');
        await AttendanceDBHelper.instance.markLeave(_email!);
        await LeaveReportsDBHelper.instance.leaveApplication(_username!,_email!, leaveRequest);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave marked successfully.')),
        );
        setState(() {
          _isButtonEnabled = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark leave: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Leave')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              maxLines: 5,
              onChanged: (value) {
                setState(() {
                  leaveRequest = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Leave Request',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _updateLeaveStatus : null,
              child: const Text('Mark Leave'),
            ),
          ],
        ),
      ),
    );
  }
}
