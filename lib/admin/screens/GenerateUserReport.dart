import 'package:flutter/material.dart';
import 'package:attendy_sqlite/user/models/attendance_db_helper.dart';
import 'package:screenshot/screenshot.dart';

class GenerateUserReport extends StatefulWidget {
  final String username;
  final String startDate;
  final String endDate;
  final String email;

  const GenerateUserReport({
    super.key,
    required this.username,
    required this.email,
    required this.startDate,
    required this.endDate,
  });

  @override
  _GenerateUserReportState createState() => _GenerateUserReportState();
}

class _GenerateUserReportState extends State<GenerateUserReport> {
  late Future<Map<String, int>> attendanceSummary;
  late int totalDays;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    attendanceSummary = fetchAttendanceSummary();
    totalDays = DateTime.parse(widget.endDate)
            .difference(DateTime.parse(widget.startDate))
            .inDays +
        1;
  }

  Future<Map<String, int>> fetchAttendanceSummary() async {
    final dbHelper = AttendanceDBHelper.instance;
    int totalPresent = await dbHelper.totalPresentCount(
        widget.email, widget.startDate, widget.endDate);
    int totalAbsent = await dbHelper.totalAbsentCount(
        widget.email, widget.startDate, widget.endDate);
    int totalLeave = await dbHelper.totalLeaveCount(
        widget.email, widget.startDate, widget.endDate);

    return {
      'totalPresent': totalPresent,
      'totalAbsent': totalAbsent,
      'totalLeave': totalLeave,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Attendance Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start Date: ${widget.startDate}'),
            Text('End Date: ${widget.endDate}'),
            const SizedBox(height: 20),
            Text(
              '${widget.username} Attendance Report',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: attendanceSummary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('No attendance data found.');
                } else {
                  final data = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfoRow('Username', widget.username),
                      buildInfoRow('Email', widget.email),
                      buildInfoRow(
                          'Total Present', data['totalPresent']!.toString()),
                      buildInfoRow(
                          'Total Absent', data['totalAbsent']!.toString()),
                      buildInfoRow(
                          'Total Leave', data['totalLeave']!.toString()),
                      buildInfoRow('Total Days', totalDays.toString()),
                      buildInfoRow(
                          'Grade', calculateGrade(data['totalPresent']!)),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            const Row(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value),
        ],
      ),
    );
  }

  String calculateGrade(int totalPresent) {
    double presentRatio = totalPresent / totalDays;
    if (presentRatio >= 0.8) {
      return 'A';
    } else if (presentRatio >= 0.6) {
      return 'B';
    } else if (presentRatio >= 0.4) {
      return 'C';
    } else if(presentRatio >= 0.3){
      return 'D';
    } else {
      return 'F';
    }
  }

}