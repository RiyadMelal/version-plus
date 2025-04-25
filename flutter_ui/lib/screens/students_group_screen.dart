import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../api_service.dart';

class StudentsGroupScreen extends StatefulWidget {
  final int groupId;

  const StudentsGroupScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  _StudentsGroupScreenState createState() => _StudentsGroupScreenState();
}

class _StudentsGroupScreenState extends State<StudentsGroupScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = '';

  @override
  void initState() {
    super.initState();
    _refreshStudents();
    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStudents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      students = await ApiService.getStudentsByGroup(widget.groupId);
      filteredStudents = List.from(students);
      setState(() {
        isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredStudents = List.from(students);
      });
      _applySorting();
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        final firstName = (student['fname'] ?? '').toString().toLowerCase();
        final lastName = (student['name'] ?? '').toString().toLowerCase();
        final email = (student['email'] ?? '').toString().toLowerCase();
        //final phone = (student['phone'] ?? '').toString().toLowerCase();

        return firstName.contains(lowerQuery) ||
            lastName.contains(lowerQuery) ||
            email.contains(lowerQuery);// ||
           // phone.contains(lowerQuery);
      }).toList();
    });
  }

  void _applySorting() {
    setState(() {
      if (_sortBy == 'name_asc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['fname']} ${a['name']}'.toLowerCase();
          final nameB = '${b['first_name']} ${b['last_name']}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
      } else if (_sortBy == 'name_desc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['first_name']} ${a['last_name']}'.toLowerCase();
          final nameB = '${b['first_name']} ${b['last_name']}'.toLowerCase();
          return nameB.compareTo(nameA);
        });
      } else if (_sortBy == 'email_asc') {
        filteredStudents.sort((a, b) {
          final emailA = (a['email'] ?? '').toString().toLowerCase();
          final emailB = (b['email'] ?? '').toString().toLowerCase();
          return emailA.compareTo(emailB);
        });
      } else if (_sortBy == 'email_desc') {
        filteredStudents.sort((a, b) {
          final emailA = (a['email'] ?? '').toString().toLowerCase();
          final emailB = (b['email'] ?? '').toString().toLowerCase();
          return emailB.compareTo(emailA);
        });
      }
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sort Options', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('Default')),
                  DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                  DropdownMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                  DropdownMenuItem(value: 'email_asc', child: Text('Email (A-Z)')),
                  DropdownMenuItem(value: 'email_desc', child: Text('Email (Z-A)')),
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
                  _sortBy = tempSortBy;
                });
                _applySorting();
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

  void _showAddStudentDialog() {
    final TextEditingController _firstNameController = TextEditingController();
    final TextEditingController _lastNameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
   

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add New Student', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
              
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
                if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('First name and last name are required')),
                  );
                  return;
                }

                try {
                  final studentData = {
                    'fname': _firstNameController.text,
                    'name': _lastNameController.text,
                    'email': _emailController.text,
                    'group_id': widget.groupId,
                  };

                  await ApiService.createStudent(studentData);
                  _refreshStudents();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Student added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add student: $e')),
                  );
                }
              },
              child: Text('Add'),
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

  void _showEditStudentDialog(dynamic student) {
    final TextEditingController _firstNameController = TextEditingController(
      text: student['fname'] ?? '',
    );
    final TextEditingController _lastNameController = TextEditingController(
      text: student['name'] ?? '',
    );
    final TextEditingController _emailController = TextEditingController(
      text: student['email'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Student', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                
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
                if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('First name and last name are required')),
                  );
                  return;
                }

                try {
                  final studentId = int.parse(student['id'].toString());
                  final studentData = {
                    'fname': _firstNameController.text,
                    'name': _lastNameController.text,
                    'email': _emailController.text,
                    'group_id':widget.groupId
                  };

                  await ApiService.updateStudent(widget.groupId,studentId, studentData);
                  _refreshStudents();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Student updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update student: $e')),
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

  void _confirmDeleteStudent(int studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteStudent(studentId);
                _refreshStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Student deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete student: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailsDialog(dynamic student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              'Student Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('First Name', student['fname'] ?? 'N/A'),
              _buildInfoRow('Last Name', student['name'] ?? 'N/A'),
              _buildInfoRow('Email', student['email'] ?? 'N/A'),
              _buildInfoRow('Created At', _formatDateTime(student['created_at'])),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.cyan)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not available';
    try {
      final DateTime dt = DateTime.parse(dateTime.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    return RefreshIndicator(
      onRefresh: _refreshStudents,
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
                      hintText: 'Search students...',
                      prefixIcon: Icon(FontAwesomeIcons.search, color: Colors.cyan, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(FontAwesomeIcons.xmark, color: Colors.blueGrey.shade700, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            filteredStudents = List.from(students);
                            _applySorting();
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
                      FontAwesomeIcons.arrowUpZA,
                      color: Colors.cyan,
                      size: 20,
                    ),
                    onPressed: _showSortDialog,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Students (${filteredStudents.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  icon: Icon(FontAwesomeIcons.plus, size: 16),
                  label: Text('Add  a Student'),
                  onPressed: _showAddStudentDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: students.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.userGroup, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No students in this group',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddStudentDialog,
                      child: Text('Add First Student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : filteredStudents.isEmpty
                  ? Center(
                child: Text('No matching students found', style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showStudentDetailsDialog(student),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.cyan.shade100,
                              radius: 25,
                              child: Text(
                                '${student['fname']?[0]}${student['name']?[0]}',
                                style: TextStyle(
                                  color: Colors.cyan.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${student['fname']} ${student['name']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    student['email'] ?? 'No email',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.pen, size: 16, color: Colors.teal),
                                  onPressed: () => _showEditStudentDialog(student),
                                ),
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                                  onPressed: () {
                                    final studentId = int.parse(student['id'].toString());
                                    _confirmDeleteStudent(studentId);
                                  },
                                ),
                              ],
                            ),
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