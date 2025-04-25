import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final int sessionId;
  final int groupId;
  final String sessionDate;

  const AttendanceScreen({
    Key? key,
    required this.sessionId,
    required this.groupId,
    required this.sessionDate,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> students = [];
  Map<int, bool> attendanceStatus = {};
  bool hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  static AttendanceScreen fromArguments(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return AttendanceScreen(
      sessionId: args['sessionId'],
      groupId: args['groupId'],
      sessionDate: args['sessionDate'],
    );
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Load students for this group
      final studentsData = await ApiService.getStudentsByGroup(widget.groupId);

      // Load existing attendance records for this session
      final attendanceData = await ApiService.getAttendanceBySession(widget.sessionId);

      // Initialize attendance status map
      Map<int, bool> status = {};
      for (var student in studentsData) {
        int studentId = int.parse(student['id'].toString());
        // Check if student is marked as present in existing attendance data
        bool isPresent = attendanceData.any((record) =>
        int.parse(record['student_id'].toString()) == studentId &&
            record['status'] == 'present'
        );
        status[studentId] = isPresent;
      }

      setState(() {
        students = studentsData;
        attendanceStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare attendance data
      List<Map<String, dynamic>> attendanceData = [];
      attendanceStatus.forEach((studentId, isPresent) {
        attendanceData.add({
          'student_id': studentId,
          'session_id': widget.sessionId,
          'status': isPresent ? 'present' : 'absent',
          'note': '', // Optional note field
        });
      });

      // Use the bulkCreateAttendance method from ApiService instead
      await ApiService.bulkCreateAttendance(widget.sessionId, attendanceData);

      setState(() {
        isLoading = false;
        hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e')),
      );
    }
  }

  void _toggleAttendance(int studentId, bool value) {
    setState(() {
      attendanceStatus[studentId] = value;
      hasUnsavedChanges = true;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var student in students) {
        int studentId = int.parse(student['id'].toString());
        attendanceStatus[studentId] = true;
      }
      hasUnsavedChanges = true;
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var student in students) {
        int studentId = int.parse(student['id'].toString());
        attendanceStatus[studentId] = false;
      }
      hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (hasUnsavedChanges) {
          // Show dialog to confirm leaving without saving
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('You have unsaved attendance changes. Do you want to save before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Leave Without Saving'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveAttendance();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save and Leave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Take Attendance'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.floppyDisk),
              onPressed: _saveAttendance,
              tooltip: 'Save Attendance',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text('Error: $error'))
            : Column(
          children: [
            _buildSessionInfo(),
            _buildActionButtons(),
            Expanded(
              child: _buildStudentsList(),
            ),
          ],
        ),
        bottomNavigationBar: hasUnsavedChanges
            ? Container(
          color: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text('You have unsaved changes', style: TextStyle(color: Colors.amber.shade900)),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveAttendance,
                child: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                ),
              ),
            ],
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.calendarDay, color: Colors.cyan),
              const SizedBox(width: 12),
              Text(
                widget.sessionDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Students: ${students.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Present: ${attendanceStatus.values.where((present) => present).length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.check, size: 16),
              label: const Text('Mark All Present'),
              onPressed: _markAllPresent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark, size: 16),
              label: const Text('Mark All Absent'),
              onPressed: _markAllAbsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.userGroup, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No students in this group',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = int.parse(student['id'].toString());
        final isPresent = attendanceStatus[studentId] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.cyan.shade100,
              child: Text(
                '${student['first_name']?[0]}${student['last_name']?[0]}',
                style: TextStyle(color: Colors.cyan.shade800),
              ),
            ),
            title: Text(
              '${student['first_name']} ${student['last_name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(student['email'] ?? 'No email'),
            trailing: Switch(
              value: isPresent,
              onChanged: (value) => _toggleAttendance(studentId, value),
              activeColor: Colors.green,
              activeTrackColor: Colors.green.shade100,
            ),
          ),
        );
      },
    );
  }
}