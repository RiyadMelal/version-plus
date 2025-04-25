// ignore_for_file: empty_statements

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'sessions_screen.dart';
import 'dart:math' as math;

import '../api_service.dart';
import 'screens/attendance_screen.dart';  // Add proper import for AttendanceScreen
import 'screens/students_group_screen.dart';

class SessionScreen extends StatefulWidget {
  final String groupName;
  final int groupId;

  const SessionScreen({
    Key? key,
    required this.groupName,
    required this.groupId,
  }) : super(key: key);

  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  String? error;
  List<dynamic> sessions = [];
  List<dynamic> filteredSessions = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterPeriod = 'all';
  String _sortBy = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshSessions();
    _searchController.addListener(() {
      _filterSessions(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshSessions() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      sessions = await ApiService.getSessionsByGroup(widget.groupId);
      filteredSessions = List.from(sessions);
      setState(() {
        isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _filterSessions(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSessions = List.from(sessions);
      });
      _applyFilters();
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredSessions = sessions.where((session) {
        final date = formatDate(session['s_date']).toLowerCase();
        final time = formatTime(session['s_date']).toLowerCase();
        final comment = (session['comment'] ?? '').toString().toLowerCase();

        return date.contains(lowerQuery) ||
            time.contains(lowerQuery) ||
            comment.contains(lowerQuery);
      }).toList();
    });
  }

  void _applyFilters() {
    final now = DateTime.now();

    setState(() {
      if (_filterPeriod == 'all') {
        filteredSessions = List.from(sessions);
      } else {
        filteredSessions = sessions.where((session) {
          final sessionDate = DateTime.tryParse(session['s_date'] ?? '');
          if (sessionDate == null) return false;

          switch (_filterPeriod) {
            case 'last_day':
              return now.difference(sessionDate).inDays <= 1;
            case 'last_week':
              return now.difference(sessionDate).inDays <= 7;
            case 'last_month':
              return now.difference(sessionDate).inDays <= 30;
            case 'past':
              return sessionDate.isBefore(now);
            default:
              return true;
          }
        }).toList();
      }

      // Apply sorting
      if (_sortBy == 'date_asc') {
        filteredSessions.sort((a, b) {
          final dateA = DateTime.tryParse(a['s_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['s_date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
      } else if (_sortBy == 'date_desc') {
        filteredSessions.sort((a, b) {
          final dateA = DateTime.tryParse(a['s_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['s_date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempFilterPeriod = _filterPeriod;
        String tempSortBy = _sortBy;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Filter Options', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time Period Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Time Period',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: tempFilterPeriod,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Sessions')),
                  DropdownMenuItem(value: 'last_day', child: Text('Last Day')),
                  DropdownMenuItem(value: 'last_week', child: Text('Last Week')),
                  DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                  DropdownMenuItem(value: 'past', child: Text('Past Sessions')),
                ],
                onChanged: (value) => tempFilterPeriod = value ?? 'all',
              ),
              SizedBox(height: 16),

              // Sort By Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('Default')),
                  DropdownMenuItem(value: 'date_asc', child: Text('Date (Oldest First)')),
                  DropdownMenuItem(value: 'date_desc', child: Text('Date (Newest First)')),
                ],
                onChanged: (value) => tempSortBy = value ?? '',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterPeriod = tempFilterPeriod;
                  _sortBy = tempSortBy;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSessionDialog() {
    final TextEditingController _dateController = TextEditingController();
    final TextEditingController _endDateController = TextEditingController();
    final TextEditingController _commentController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    DateTime selectedEndDate = DateTime.now().add(Duration(hours: 2));

    _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
    _endDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedEndDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Create New Session', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDateTimeField(
                  controller: _dateController,
                  label: 'Start Date & Time',
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
                      }
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildDateTimeField(
                  controller: _endDateController,
                  label: 'End Date & Time',
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndDate),
                      );
                      if (pickedTime != null) {
                        selectedEndDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _endDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedEndDate);
                      }
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final sessionData = {
                    's_date': _dateController.text,
                    'end_date': _endDateController.text,
                    'comment': _commentController.text,
                    'group_id': widget.groupId,
                  };

                  await ApiService.createSession(widget.groupId, sessionData);
                  _refreshSessions();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create session: $e')),
                  );
                }
              },
              child: Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: Icon(Icons.calendar_today),
      ),
    );
  }

  void _confirmDeleteSession(int sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteSession(sessionId);
                _refreshSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Session deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete session: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSessionDialog(dynamic session) {
    final TextEditingController _dateController = TextEditingController(
      text: session['s_date'] ?? '',
    );
    final TextEditingController _endDateController = TextEditingController(
      text: session['end_date'] ?? '',
    );
    final TextEditingController _commentController = TextEditingController(
      text: session['comment'] ?? '',
    );

    DateTime? selectedDate = DateTime.tryParse(session['s_date'] ?? '');
    DateTime? selectedEndDate = DateTime.tryParse(session['end_date'] ?? '');

    if (selectedDate == null) selectedDate = DateTime.now();
    if (selectedEndDate == null) selectedEndDate = DateTime.now().add(Duration(hours: 2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Session', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDateTimeField(
                  controller: _dateController,
                  label: 'Start Date & Time',
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate!),
                      );
                      if (pickedTime != null) {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate!);
                      }
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildDateTimeField(
                  controller: _endDateController,
                  label: 'End Date & Time',
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndDate!),
                      );
                      if (pickedTime != null) {
                        selectedEndDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _endDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedEndDate!);
                      }
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final sessionId = int.parse(session['id'].toString());
                  final sessionData = {
                    's_date': _dateController.text,
                    'end_date': _endDateController.text,
                    'comment': _commentController.text,
                  };

                  await ApiService.updateSession(widget.groupId,sessionId, sessionData);
                  _refreshSessions();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update session: $e')),
                  );
                }
              },
              child: Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

void _showSessionDetailsDialog(dynamic session) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Session Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Start Date', formatDateTime(session['s_date'])),
            _buildInfoRow('End Date', formatDateTime(session['end_date'])),
            _buildInfoRow('Comment', session['comment'] ?? 'No comment'),
            _buildInfoRow('Created At', formatDateTime(session['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close', style: TextStyle(color: Colors.cyan)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final sessionId = int.parse(session['id'].toString());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceScreen(
                    sessionId: sessionId,
                    groupId: widget.groupId,
                    sessionDate: formatDateTime(session['s_date']),
                  ),
                ),
              );
            },
            child: Text('Take Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    },
  );
}

  String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not set';
    try {
      final DateTime dt = DateTime.parse(dateTime.toString());
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  String formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr.toString());
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return dateStr.toString().substring(0, 10);
    }
  }

  String formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr.toString());
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.calendarDays, size: 16),
                          SizedBox(width: 8),
                          Text('Sessions'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.userGroup, size: 16),
                          SizedBox(width: 8),
                          Text('Students'),
                        ],
                      ),
                    ),
                  ],
                  labelColor: Colors.cyan,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.cyan,
                  indicatorWeight: 3,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionsTab(),
                    StudentsGroupScreen(groupId: widget.groupId),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: WavePainter(tabController: _tabController),
              size: Size(MediaQuery.of(context).size.width, 100),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSessionDialog,
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.calendar, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sessions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateSessionDialog,
              child: Text('Create First Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSessions,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by date, time or comment...',
                      prefixIcon: Icon(FontAwesomeIcons.search, color: Colors.cyan, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(FontAwesomeIcons.xmark, color: Colors.blueGrey.shade700, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  filteredSessions = List.from(sessions);
                                  _applyFilters();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: IconButton(
                    icon: Icon(
                      FontAwesomeIcons.sliders,
                      color: Colors.cyan,
                      size: 20,
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Text('No matching sessions found', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final sessionId = int.parse(session['id'].toString());
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendanceScreen(
                                    sessionId: sessionId,
                                    groupId: widget.groupId,
                                    sessionDate: formatDateTime(session['s_date']),
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _showSessionDetailsDialog(session),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.calendarCheck,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        formatDate(session['s_date']),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(FontAwesomeIcons.pen, size: 18, color: Colors.teal),
                                            onPressed: () => _showEditSessionDialog(session),
                                          ),
                                          IconButton(
                                            icon: Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red),
                                            onPressed: () {
                                              final sessionId = int.parse(session['id'].toString());
                                              _confirmDeleteSession(sessionId);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.clock,
                                        color: Colors.blueGrey,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${formatTime(session['s_date'])} - ${formatTime(session['end_date'])}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  if (session['comment'] != null && session['comment'].toString().isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.comment,
                                          color: Colors.blueGrey,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            session['comment'].toString(),
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
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

class WavePainter extends CustomPainter {
  final TabController tabController;

  WavePainter({required this.tabController});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height;
    final width = size.width;

    path.moveTo(0, height * 0.5);
    path.quadraticBezierTo(
      width * 0.25,
      height * (tabController.index == 0 ? 0.2 : 0.8),
      width * 0.5,
      height * 0.5,
    );
    path.quadraticBezierTo(
      width * 0.75,
      height * (tabController.index == 0 ? 0.8 : 0.2),
      width,
      height * 0.5,
    );
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}