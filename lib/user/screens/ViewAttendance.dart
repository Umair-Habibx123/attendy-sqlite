import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  _ViewAttendanceScreenState createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  AttendanceDBHelper attendanceDBHelper = AttendanceDBHelper.instance;
  late String _email;
  String? selectedFromDate;
  String? selectedToDate;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('email') ?? '';
    await _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    if (_email.isNotEmpty) {
      final records = await attendanceDBHelper.getAttendanceRecords(_email);
      setState(() {
        _attendanceRecords = records;
      });
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
    if (selectedFromDate != null && selectedToDate != null) {
      try {
        List<Map<String, dynamic>> filteredRecords =
            await AttendanceDBHelper.instance.getAttendanceRecordsRange(
          _email,
          selectedFromDate!,
          selectedToDate!,
        );
        setState(() {
          _attendanceRecords = filteredRecords;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             
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
            const SizedBox(height: 20),
            Expanded(
  child: _attendanceRecords.isEmpty
      ? const Center(
          child: Text('No attendance records found.'),
        )
      : ListView.builder(
          itemCount: _attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = _attendanceRecords[index];
            final status = record['status'];
            final statusColor = status == 'present'
                ? Colors.lightGreen
                : status == 'absent'
                    ? Colors.red
                    : status == 'On Leave'
                        ? Colors.blue
                        : Colors.black; // Default color for other statuses

            return ListTile(
              title: Text(
                record['date'],
                // style: TextStyle(color: statusColor),
              ),
              subtitle: Text(
                record['status'],
                style: TextStyle(color: statusColor),
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
