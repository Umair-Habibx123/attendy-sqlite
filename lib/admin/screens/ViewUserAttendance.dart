import 'dart:typed_data';
import 'package:attendy_sqlite/admin/screens/GenerateUserReport.dart';
import 'package:attendy_sqlite/admin/screens/LeaveApplication.dart';
import 'package:attendy_sqlite/user/models/LeaveReportsDBHelper.dart';
import 'package:flutter/material.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';
import 'package:attendy_sqlite/shared/models/UserDBHelper.dart';
import 'package:intl/intl.dart';

class ViewUserAttendance extends StatefulWidget {
  final String username;

  const ViewUserAttendance({super.key, required this.username});

  @override
  _ViewUserAttendanceState createState() => _ViewUserAttendanceState();
}

class _ViewUserAttendanceState extends State<ViewUserAttendance> {
  String email = '';
  String? selectedFromDate = '';
  String? selectedToDate = '';
  List<Map<String, dynamic>> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    fetchUserDetailsAndAttendance();
  }

  Future<void> _addAttendance() async {
    DateTime fromDate = DateFormat('yyyy-MM-dd').parse(selectedFromDate!);
    DateTime toDate = DateFormat('yyyy-MM-dd').parse(selectedToDate!);

    if (selectedFromDate == '' && selectedToDate == '') {
      // if(fromDate.toString() == '' && toDate .toString() == ''){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To dates.'),
        ),
      );
      return;
    } else if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be less than end date.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String dropdownValue = 'present';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Attendance Confirmation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Are you sure you want to add attendance for selected dates?'),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: dropdownValue,
                    items: <String>['present', 'absent', 'On Leave']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          dropdownValue = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _insertAttendance(
                      selectedFromDate!,
                      selectedToDate!,
                      dropdownValue,
                    );
                  },
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAttendance() async {
    DateTime fromDate = DateFormat('yyyy-MM-dd').parse(selectedFromDate!);
    DateTime toDate = DateFormat('yyyy-MM-dd').parse(selectedToDate!);

    if (selectedFromDate == '' && selectedToDate == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To dates.'),
        ),
      );
      return;
    } else if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be less than end date.'),
        ),
      );
      return;
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('delete Attendance Confirmation'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Are you sure you want to add attendance for selected dates?'),
                SizedBox(height: 20),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteBatchAttendance(selectedFromDate!, selectedToDate!);
                },
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _deleteBatchAttendance(String fromDate, String toDate) async {
    try {
      bool success = await AttendanceDBHelper.instance
          .deleteAttendanceRange(email, fromDate, toDate);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance deleted successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance doesn\'t exists'),
          ),
        );
      }
      fetchUserDetailsAndAttendance();
    } catch (e) {
      print('Error deleting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete attendance.'),
        ),
      );
    }
  }

  Future<void> _insertAttendance(
      String fromDate, String toDate, String status) async {
    try {
      bool success = await AttendanceDBHelper.instance
          .insertAttendanceRange(email, fromDate, toDate, status);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance added successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance Already exists'),
          ),
        );
      }
      fetchUserDetailsAndAttendance();
    } catch (e) {
      print('Error inserting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add attendance.'),
        ),
      );
    }
  }

  Future<void> fetchUserDetailsAndAttendance() async {
    try {
      Map<String, dynamic>? userDetails =
          await UserDBHelper.instance.getUserDetailsByUsername(widget.username);
      if (userDetails != null) {
        setState(() {
          email = userDetails['email'] ?? '';
        });

        List<Map<String, dynamic>> records =
            await AttendanceDBHelper.instance.getAttendanceRecords(email);
        setState(() {
          attendanceRecords = records;
        });
      } else {}
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          selectedFromDate = DateFormat('yyyy-MM-dd').format(pickedDate);
        } else {
          selectedToDate = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
        filterAttendanceList();
      });
    }
  }

  Future<void> filterAttendanceList() async {
    if (selectedFromDate != '' && selectedToDate != '') {
      try {
        List<Map<String, dynamic>> filteredRecords =
            await AttendanceDBHelper.instance.getAttendanceRecordsRange(
                email, selectedFromDate!, selectedToDate!);
        setState(() {
          attendanceRecords = filteredRecords;
        });
      } catch (e) {
        print('Error: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To dates.'),
        ),
      );
    }
  }

  Future<void> generateUserReport() async {
    DateTime fromDate = DateFormat('yyyy-MM-dd').parse(selectedFromDate!);
    DateTime toDate = DateFormat('yyyy-MM-dd').parse(selectedToDate!);

    if (selectedFromDate == '' || selectedToDate == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To dates.'),
        ),
      );
      return;
    } else if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be less than or equal to end date.'),
        ),
      );
      return;
    }

    bool range = await AttendanceDBHelper.instance
        .checkAttendanceRecordsRange(email, selectedFromDate!, selectedToDate!);

    if (!range) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid dates: some days are missing in attendance records.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerateUserReport(
          username: widget.username,
          startDate: selectedFromDate!,
          endDate: selectedToDate!,
          email: email,
        ),
      ),
    );
  }

  Future<void> _navigateToLeaveApplication(
      Map<String, dynamic> attendanceRecord) async {
    try {
      String date = attendanceRecord['date'] ?? '';
      String username = widget.username;
      String email = this.email;

      String leave = await LeaveReportsDBHelper.instance
          .sendLeaveApplication(username, email, date);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeaveApplication(
            username: username,
            email: email,
            date: date,
            leave: leave,
          ),
        ),
      );
    } catch (e) {
      print('Error fetching leave application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch leave application.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: UserDBHelper.instance
                  .getUserDetailsByUsername(widget.username),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return const Text('Error fetching user details.');
                }

                final userDetails = snapshot.data!;
                final String username =
                    userDetails['username'] ?? 'Username not found';
                final String email = userDetails['email'] ?? 'Email not found';
                final Uint8List? profilePicture = userDetails['profilePicture'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: profilePicture != null
                          ? MemoryImage(profilePicture)
                          : null,
                      child: profilePicture == null
                          ? const Icon(Icons.account_circle, size: 60)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: $username',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Email: $email',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From: '),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(10),
                          ),
                          child: Text(selectedFromDate ?? 'Select From Date'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To: '),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(10),
                          ),
                          child: Text(selectedToDate ?? 'Select To Date'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    minimumSize: const Size(30, 0),
                  ),
                  child: const Text('Add Attendance'),
                ),
                ElevatedButton(
                  onPressed: _deleteAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    minimumSize: const Size(30, 0),
                  ),
                  child: const Text('Delete Attendance'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: generateUserReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    minimumSize: const Size(30, 0),
                  ),
                  child: const Text('Generate Report'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  final attendanceRecord = attendanceRecords[index];
                  final String date =
                      attendanceRecord['date'] ?? 'Date not found';
                  String status =
                      attendanceRecord['status'] ?? 'Status not found';

                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: $date',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              status == 'On Leave'
                                  ? GestureDetector(
                                      onTap: () {
                                        _navigateToLeaveApplication(
                                            attendanceRecord);
                                      },
                                      child: Text(
                                        'Status: $status',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.blue,
                                          decoration: TextDecoration
                                              .underline, // Underline the text
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: status == 'absent'
                                            ? Colors.red
                                            : status == 'present'
                                                ? Colors.lightGreen
                                                : Colors
                                                    .black, // Default color for other statuses
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        DropdownButton<String>(
                          value: status,
                          items: <String>['present', 'absent', 'On Leave']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              bool success = await AttendanceDBHelper.instance
                                  .updateAttendanceStatus(
                                      email, date, newValue);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Attendance updated successfully'),
                                  ),
                                );
                                fetchUserDetailsAndAttendance();
                                setState(() {
                                  attendanceRecords[index]['status'] = newValue;
                                  status = newValue;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to update attendance status'),
                                  ),
                                );
                              }
                            }
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
      ),
    );
  }
}
