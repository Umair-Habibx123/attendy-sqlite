import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendy_sqlite/shared/screens/login.dart';
import 'package:attendy_sqlite/user/user.dart';  
import 'package:attendy_sqlite/admin/admin.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String role = prefs.getString('role') ?? '';

  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;

  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;

    if (isLoggedIn) {
      if (role == 'admin') {
        homeWidget = const AdminApp();
      } else {
        homeWidget = const UserApp();
      }
    }
    else {
      homeWidget = const LoginScreen();
    }

    return MaterialApp(
      title: 'Attendy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: homeWidget,
    );
  }
}
