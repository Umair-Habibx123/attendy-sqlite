import 'package:flutter/material.dart';
import 'package:attendy_sqlite/admin/screens/ViewUserAttendance.dart';
import 'package:attendy_sqlite/shared/models/UserDBHelper.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';
import 'package:attendy_sqlite/user/models/LeaveReportsDBHelper.dart';

class Alluserslist extends StatefulWidget {
  const Alluserslist({super.key});

  @override
  _AlluserslistState createState() => _AlluserslistState();
}

class _AlluserslistState extends State<Alluserslist> {
  List<String> _usernames = [];
  List<String> _filteredUsernames = [];

  @override
  void initState() {
    super.initState();
    _loadUserList();
  }

  Future<void> _loadUserList() async {
    List<String> usernames =
        await UserDBHelper.instance.getUsernamesWithRoleUser();
    setState(() {
      _usernames = usernames;
      _filteredUsernames = usernames;
    });
  }

  void _filterUsernames(String query) {
    List<String> filteredUsernames = _usernames.where((username) {
      return username.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredUsernames = filteredUsernames;
    });
  }

  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text(
              'Are you sure? If you delete, this action is permanent and all data including attendance records will be lost.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'No',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                String? email =
                    await UserDBHelper.instance.deleteUserByUsername(username);
                if (email != null) {
                  await AttendanceDBHelper.instance
                      .deleteUserAttendanceByEmail(email);
                  await LeaveReportsDBHelper.instance
                      .deleteUserLeaveByEmail(email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User not found or email is null.'),
                    ),
                  );
                }

                Navigator.of(context).pop();
                _loadUserList();
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.green),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _filterUsernames,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsernames.length,
              itemBuilder: (context, index) {
                final username = _filteredUsernames[index];
                return ListTile(
                  title: Text(username),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewUserAttendance(username: username),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(username);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
