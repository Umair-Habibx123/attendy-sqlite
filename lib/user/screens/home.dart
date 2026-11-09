import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendy_sqlite/user/screens/MarkAttendance.dart';
import 'package:attendy_sqlite/user/screens/ViewAttendance.dart';
import 'package:attendy_sqlite/user/screens/MarkLeave.dart';
import 'package:attendy_sqlite/user/screens/update_profile.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int userId;
  late String username;
  late String email;
  late String password;
  late String role;
  bool _isMarkAttendanceEnabled = false;
  bool _isMarkLeaveEnabled = false;
  AttendanceDBHelper attendanceDBHelper = AttendanceDBHelper.instance;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAttendanceAndLeaveStatus();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId') ?? 0;
      username = prefs.getString('username') ?? '';
      email = prefs.getString('email') ?? '';
      password = prefs.getString('password') ?? '';
      role = prefs.getString('role') ?? '';
      profilePictureUrl = prefs.getString('profilePictureUrl');
    });
  }

  Future<void> _checkAttendanceAndLeaveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email != null) {
      bool todayAttendance = await attendanceDBHelper.getTodayAttendance(email);
      
      final currentTime = DateTime.now();
      final currentHour = currentTime.hour;

      setState(() {
         
        if (todayAttendance) {
          _isMarkAttendanceEnabled = false;
          _isMarkLeaveEnabled = false;
        } else {
          
          if (!todayAttendance && (currentHour >= 8 && currentHour < 13)) {
            _isMarkAttendanceEnabled = true;
            _isMarkLeaveEnabled = true;
          } else if (!todayAttendance && currentHour >= 13) {
            
            _isMarkAttendanceEnabled = false;
            _isMarkLeaveEnabled = false;
              _markAttendanceAsAbsent();
          }
        }
      });
    }
  }

  Future<void> _markAttendanceAsAbsent() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      await attendanceDBHelper.markAttendanceAsAbsent(email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marked as absent automatically.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance as absent: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen(),
                ),
              );
            },
            icon: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage:
                        MemoryImage(base64Decode(profilePictureUrl!)),
                  )
                : const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isMarkAttendanceEnabled
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceButton(),
                        ),
                      ).then((_) {
                        _checkAttendanceAndLeaveStatus();
                      });
                    }
                  : null,
              child: const Text('Mark Attendance'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isMarkLeaveEnabled
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarkLeaveScreen(),
                        ),
                      ).then((_) {
                        _checkAttendanceAndLeaveStatus();
                      });
                    }
                  : null,
              child: const Text('Mark Leave'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewAttendanceScreen(),
                  ),
                );
              },
              child: const Text('View Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
