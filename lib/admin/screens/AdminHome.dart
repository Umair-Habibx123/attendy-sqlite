import 'dart:convert';
import 'package:attendy_sqlite/admin/screens/AdminUpdate_profile.dart';
import 'package:attendy_sqlite/admin/screens/AllUsersList.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int userId;
  late String username;
  late String email;
  late String password;
  late String role;
  String? profilePictureUrl;
  final bool _isBtnEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    username = prefs.getString('username') ?? '';
    email = prefs.getString('email') ?? '';
    password = prefs.getString('password') ?? '';
    role = prefs.getString('role') ?? '';
    profilePictureUrl = prefs.getString('profilePictureUrl');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminUpdateProfileScreen()),
              );
            },
            icon: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: MemoryImage(base64Decode(profilePictureUrl!)),
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
              onPressed: _isBtnEnabled
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Alluserslist()),
                      );
                    }
                  : null,
              child: const Text('View All Users'),
            ),
          ],
        ),
      ),
    );
  }
}
