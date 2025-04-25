import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class SessionsScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const SessionsScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> sessions = [];
  List<dynamic> _filteredSessions = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _searchController.addListener(() {
      _search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final loadedSessions = await ApiService.getSessionsByGroup(widget.groupId);
      if (mounted) {
        setState(() {
          sessions = loadedSessions;
          _filteredSessions = List.from(sessions);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredSessions = sessions.where((session) {
        return session['comment'].toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _showCreateSessionDialog() {
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();
    final _commentController = TextEditingController();
    
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

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
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        selectedStartDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _startDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedStartDate!);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _startDateController, 
                      'Start Date and Time',
                      prefix: Icon(Icons.calendar_today, color: Colors.cyan),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        selectedEndDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _endDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedEndDate!);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _endDateController, 
                      'End Date and Time',
                      prefix: Icon(Icons.calendar_today, color: Colors.cyan),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                _buildTextField(_commentController, 'Comment/Description'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Create'),
              onPressed: () async {
                if (selectedStartDate == null || selectedEndDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select both start and end dates')),
                  );
                  return;
                }
                
                if (_commentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a comment or description')),
                  );
                  return;
                }

                Map<String, dynamic> newSession = {
                  's_date': _startDateController.text,
                  'end_date': _endDateController.text,
                  'comment': _commentController.text,
                  'group_id': widget.groupId,
                };

                try {
                  await ApiService.createSession(widget.groupId, newSession);
                  Navigator.pop(context);
                  await _loadSessions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create session: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditSessionDialog(Map<String, dynamic> session) {
    final _startDateController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(session['s_date'])));
    final _endDateController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(session['end_date'])));
    final _commentController = TextEditingController(text: session['comment']);
    
    DateTime? selectedStartDate = DateTime.parse(session['s_date']);
    DateTime? selectedEndDate = DateTime.parse(session['end_date']);

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
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedStartDate ?? DateTime.now()),
                      );
                      if (pickedTime != null) {
                        selectedStartDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _startDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedStartDate!);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _startDateController, 
                      'Start Date and Time',
                      prefix: Icon(Icons.calendar_today, color: Colors.cyan),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndDate ?? DateTime.now()),
                      );
                      if (pickedTime != null) {
                        selectedEndDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _endDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedEndDate!);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _endDateController, 
                      'End Date and Time',
                      prefix: Icon(Icons.calendar_today, color: Colors.cyan),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                _buildTextField(_commentController, 'Comment/Description'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () async {
                if (selectedStartDate == null || selectedEndDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select both start and end dates')),
                  );
                  return;
                }
                
                if (_commentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a comment or description')),
                  );
                  return;
                }

                Map<String, dynamic> updatedSession = {
                  's_date': _startDateController.text,
                  'end_date': _endDateController.text,
                  'comment': _commentController.text,
                  'group_id': widget.groupId,
                };

                try {
                  await ApiService.updateSession(widget.groupId,session['id'], updatedSession);
                  Navigator.pop(context);
                  await _loadSessions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update session: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSession(int sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Optimistically update UI
                if (mounted) {
                  setState(() {
                    sessions.removeWhere((session) => session['id'] == sessionId);
                    _filteredSessions.removeWhere((session) => session['id'] == sessionId);
                  });
                }
                
                await ApiService.deleteSession(sessionId);
                
                // Refresh to ensure consistency
                await _loadSessions();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Session deleted successfully')),
                );
              } catch (e) {
                // If deletion fails, reload to restore the session
                await _loadSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete session: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {Icon? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions - ${widget.groupName}'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search session...',
                                prefixIcon: Icon(
                                  FontAwesomeIcons.search,
                                  color: Colors.cyan,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.blueGrey.shade700,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filteredSessions = List.from(sessions);
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 250,
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateSessionDialog,
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              'Create New Session',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredSessions.isEmpty
                            ? Center(
                                child: Text('No sessions found for this group',
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _filteredSessions.length,
                                itemBuilder: (context, index) {
                                  final session = _filteredSessions[index];
                                  DateTime startDate = DateTime.parse(session['s_date']);
                                  DateTime endDate = DateTime.parse(session['end_date']);
                                  
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Row(
                                        children: [
                                          Icon(Icons.event, color: Colors.cyan),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              DateFormat('EEEE, MMM d, y').format(startDate),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${DateFormat('HH:mm').format(startDate)} - ${DateFormat('HH:mm').format(endDate)}',
                                                  style: TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              session['comment'],
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showEditSessionDialog(session),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmDeleteSession(session['id']),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showEditSessionDialog(session),
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