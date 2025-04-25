import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';
import 'groups_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> specialities = [];
  List<String> levels = [];
  List<String> years = [];
  String _sortBy = '';
  String _specialty = '';
  String _year = '';
  String _level = '';
  bool isLoading = true;
  String? error;
  List<dynamic> classes = [];



  // Fetch classes and update filters
  Future<void> fetchClassesAndUpdateFilters() async {
    try {
      List classes = await ApiService.getClasses();

      // Extract unique specialities and years from the classes
      Set<String> specialities = Set();
      Set<String> levels = Set();
      Set<String> years = Set();
      for (var classData in classes) {
        if (classData['speciality'] != null) specialities.add(classData['speciality']);
        if (classData['level'] != null) levels.add(classData['level']);
        if (classData['year'] != null) years.add(classData['year']);
      }

      setState(() {
        availableSpecialities = specialities;
        availablelevel = levels;
        availableYears = years;
      });
    } catch (e) {
    }
  }


  List<Map<dynamic, dynamic>> _allClasses = [];
  List<Map<dynamic, dynamic>> _filteredClasses = [];

// To hold the unique specialities and years
  Set<String> availableSpecialities = Set();
  Set<String> availableYears = Set();
  Set<String> availablelevel = Set();




  @override
  void initState() {
    super.initState();
    _refreshClasses();
    _fetchClasses();
    _fetchClasses(); // initial load
    _searchController.addListener(() {
      setState(() {});
      specialities = classes.map((cls) => cls['speciality']?.toString() ?? '').toSet().toList();
      years = classes.map((cls) => cls['year']?.toString() ?? '').toSet().toList();
      levels = classes.map((cls) => cls['level']?.toString() ?? '').toSet().toList();
    });


  }
  @override



  @override
  void dispose() {
    super.dispose();

    fetchClassesAndUpdateFilters();

  }



  void fetchFilterOptions() {
    specialities = _allClasses
        .map((cls) => cls['speciality']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    years = _allClasses
        .map((cls) => cls['year']?.toString() ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList();
    levels = _allClasses
        .map((cls) => cls['level']?.toString() ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList();


    availableSpecialities = Set.from(specialities);
    availableYears = Set.from(years);
    availablelevel = Set.from(levels);
  }

  Future<void> _refreshClasses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      classes = await ApiService.getClasses();
      _filteredClasses = List.from(classes);
    } catch (e) {
      error = e.toString();
    }

    setState(() {
      isLoading = false;
    });
  }
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteClass(id);
                _refreshClasses();
              } catch (e) {
                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete class: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  void _showEditClassDialog(Map<dynamic, dynamic> classToEdit) {
    final _nameController = TextEditingController(text: classToEdit['name']);
    final _specialityController =
    TextEditingController(text: classToEdit['speciality']);
    final _levelController = TextEditingController(text: classToEdit['level']);
    final _semesterController =
    TextEditingController(text: classToEdit['semester'] ?? '');
    final _yearController = TextEditingController(text: classToEdit['year']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Class', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Class Name'),
                _buildTextField(_specialityController, 'Speciality'),
                _buildTextField(_levelController, 'Level'),
                _buildTextField(_semesterController, 'Semester'),
                _buildTextField(_yearController, 'Year'),
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
                // Explicitly cast the map to Map<String, dynamic>
                Map<String, dynamic> updatedData = {
                  'name': _nameController.text,
                  'speciality': _specialityController.text,
                  'level': _levelController.text,
                  'semester': _semesterController.text,
                  'year': _yearController.text,
                };

                // Make sure classToEdit['id'] is a valid integer or String
                int classId = int.tryParse(classToEdit['id'].toString()) ?? 0;
                if (classId != 0) {
                  await ApiService.updateClass(classId, updatedData);
                  _refreshClasses();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchClasses() async {
    final classes = await ApiService.getClasses();

    // Debugging output

    final convertedClasses = classes.map<Map<dynamic, dynamic>>((cls) {
      return cls.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    }).toList();

    // Debugging output

    setState(() {
      _allClasses = convertedClasses;
      _filteredClasses = List.from(_allClasses);
      fetchFilterOptions(); // Update filters after data refresh
    });
  }


  void _applyFiltersclass() {
    List<Map<dynamic, dynamic>> temp = _allClasses.where((cls) {
      final matchesSpecialty = _specialty.isEmpty || cls['speciality'] == _specialty;
      final matchesYear = _year.isEmpty || cls['year'] == _year;
      final matchesLevel = _level.isEmpty || cls['level'] == _level;  // Added level filter

      return matchesSpecialty && matchesYear && matchesLevel;  // Include the level in the filter logic
    }).toList();

    // Sorting logic
    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name']!.compareTo(b['name']!));
    } else if (_sortBy == 'time') {
      // Ensure 'time' is parsed to DateTime before sorting
      temp.sort((a, b) {
        final timeA = DateTime.tryParse(a['time'] ?? '') ?? DateTime.now();
        final timeB = DateTime.tryParse(b['time'] ?? '') ?? DateTime.now();
        return timeA.compareTo(timeB);
      });
    }

    setState(() {
      _filteredClasses = temp;
    });
  }




  @override



  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;
        String tempSpeciality = _specialty;
        String tempYear = _year;
        String tempLevel = _level;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Filter Options', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sort By Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sort by'),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'time', child: Text('Time Added')),
                ],
                onChanged: (value) => setState(() => tempSortBy = value ?? ''),
              ),

              // Speciality Dropdown - dynamically populated based on available specialities
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Speciality'),
                value: tempSpeciality.isEmpty ? null : tempSpeciality,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availableSpecialities.map((speciality) {
                    return DropdownMenuItem(value: speciality, child: Text(speciality));
                  }).toList(),
                ],
                onChanged: (value) => setState(() => tempSpeciality = value ?? ''),
              ),

              // Year Dropdown - dynamically populated based on available years
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Year'),
                value: tempYear.isEmpty ? null : tempYear,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availableYears.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                ],
                onChanged: (value) => setState(() => tempYear = value ?? ''),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Level'),
                value: tempLevel.isEmpty ? null : tempLevel,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availablelevel.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    tempLevel = value ?? '';  // Update selected level
                    _applyFiltersclass();  // Apply the filter after selection
                  });
                },
              ),


              SizedBox(height: 10),

            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sortBy = tempSortBy;
                  _specialty = tempSpeciality;
                  _year = tempYear;
                });
                _applyFiltersclass();
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredClasses = _allClasses.where((cls) {
        return cls['name']!.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _showClassDetailsDialog(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              cls['name'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Speciality', cls['speciality']),
              _buildInfoRow('Level', cls['level']),
              _buildInfoRow('Semester', cls['semester']),
              _buildInfoRow('Year', cls['year']),
              _buildInfoRow('Created At', cls['created_at']?.substring(0, 10) ?? ''),
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

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class Dashboard'),
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
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'Search class...',
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
                            _filteredClasses =
                                List.from(classes);
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        BorderSide(color: Colors.cyan, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        BorderSide(color: Colors.transparent),
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
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 250,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _showCreateClassDialog,
                  icon: SvgPicture.asset(
                    'assets/icons/plus.svg',
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Create New Class',
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
              child: _filteredClasses.isEmpty
                  ? Center(
                  child: Text('No matching classes found',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _filteredClasses.length,
                itemBuilder: (context, index) {
                  final cls = _filteredClasses[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      onTap: () {
                        // Convert the classId to int if it's a string
                        final id = cls['id'] is int ? cls['id'] :
                        (cls['id'] is String ? int.tryParse(cls['id']) : null);

                        if (id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupsScreen(
                                className: cls['name'],
                                classId: id, // Now passing a properly converted int
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid class ID')),
                          );
                        }
                      },


                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        cls['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(top: 2.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Speciality: ${cls['speciality']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'semester: ${cls['semester']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Year: ${cls['year']}',
                                style: TextStyle(fontSize: 14),
                              ),

                            ],
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesomeIcons.calendar,
                                  size: 18, color: Colors.black54),
                              SizedBox(height: 4),
                              Text(
                                  cls['created_at']
                                      ?.substring(0, 10) ??
                                      '',
                                  style:
                                  TextStyle(fontSize: 12)),

                            ],
                          ),
                          SizedBox(width: 10),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(FontAwesomeIcons.pen, size: 18, color: Colors.teal),
                                onPressed: () => _showEditClassDialog(cls),
                              ),
                              IconButton(
                                icon: Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red),
                                onPressed: () {
                                  // Check the type of cls['id'] and handle appropriately
                                  final id = cls['id'] is int ? cls['id'] : (cls['id'] is String ? int.tryParse(cls['id']) : null);

                                  if (id != null) {
                                    _confirmDelete(id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid class ID')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )                        ],
                      ),
                      onLongPress: () => _showClassDetailsDialog(Map<String, dynamic>.from(cls)),

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

  void _showCreateClassDialog() {
    final _nameController = TextEditingController();
    final _specialityController = TextEditingController();
    final _levelController = TextEditingController();
    final _semesterController = TextEditingController();
    final _yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Create New Class',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Class Name'),
                _buildTextField(_specialityController, 'Speciality'),
                _buildTextField(_levelController, 'Level'),
                _buildTextField(_semesterController, 'Semester'),
                _buildTextField(_yearController, 'Year'),
              ],
            ),
          ),
          actions: [
            TextButton(
                child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child: Text('Create'),
              onPressed: () async {
                Map<String, dynamic> newClass = {
                  'name': _nameController.text,
                  'speciality': _specialityController.text,
                  'level': _levelController.text,
                  'semester': _semesterController.text,
                  'year': _yearController.text,
                };

                await ApiService.createClass(newClass);
                _refreshClasses();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String formatDate(dynamic dateStr) {
    if (dateStr is String && dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return '';
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


}