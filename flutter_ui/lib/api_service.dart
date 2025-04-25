import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String _baseUrl =
      'http://127.0.0.1:8000/api'; // <-- FIXED here
  //http://10.0.2.2:8000/api/classes
  static const String _classesUrl = '$_baseUrl/classes';
  static const String _groupsUrl = '$_baseUrl/groups';
  static const String _studentsUrl = '$_baseUrl/students';
  static const String _attendanceUrl = '$_baseUrl/attendance';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };

  // ================================== CLASSES ===================================================================

  static Future<List<dynamic>> getClasses() async {
    try {
      final uri = Uri.parse(_classesUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No Internet');
    } catch (e) {
      throw Exception('Failed to fetch classes: $e');
    }
  }

  static Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    try {
      final response = await http
          .post(
            Uri.parse(_classesUrl),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  static Future<Map<String, dynamic>> updateClass(
      int id, Map<String, dynamic> classData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_classesUrl/$id'),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  static Future<void> deleteClass(dynamic id) async {
    try {
      // Convert id to string explicitly to ensure consistency
      final stringId = id.toString();
      final url = Uri.parse('$_classesUrl/$stringId');

      print('Deleting class with ID: $stringId');

      final response = await http
          .delete(
            url,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete class: ${response.statusCode}');
      }

      print('Class with ID $stringId successfully deleted');
    } catch (e) {
      print('Error while deleting class: $e');
      throw Exception('Failed to delete class: $e');
    }
  }

  // ========================== GROUPS=================================
  static Future<List<dynamic>> getGroupsByClass(dynamic classId) async {
    try {
      final stringId = classId.toString();
      final url = '$_baseUrl/classes/$stringId/groups';
      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);

      // Assuming your API returns { "status": "...", "data": [...] }
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      } else {
        throw Exception('Unexpected API response format');
      }
    } catch (e) {
      throw Exception('Failed to load groups for this class: $e');
    }
  }

  static Future<List<dynamic>> getGroups() async {
    try {
      final response = await http
          .get(
            Uri.parse(_groupsUrl),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleGroupResponse(response);
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  static Future<Map<String, dynamic>> createGroup(
      int classId, Map<String, dynamic> groupData) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups';
      print('Creating group at: $url with data: $groupData');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to create group (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  static Future<Map<String, dynamic>> updateGroup(
      int classId, int groupId, Map<String, dynamic> groupData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/classes/$classId/groups/$groupId'),
            headers: _headers,
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  static Future<void> deleteGroup(int classId, int groupId) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups/$groupId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // ========== SESSIONS ==========

  static const String _sessionsUrl = '$_baseUrl/session';

  // Get all sessions for a specific group
  static Future<List<dynamic>> getSessionsByGroup(int groupId) async {
    try {
      final url = '$_baseUrl/groups/$groupId/session';
      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

  // Create a session for a group
  static Future<Map<String, dynamic>> createSession(
      int groupId, Map<String, dynamic> sessionData) async {
    try {
      final url = '$_baseUrl/groups/$groupId/session';

      // Ensure keys match your database columns exactly
      final formattedData = {
        's_date': sessionData['s_date'], // Must match DB column
        'end_date': sessionData['end_date'],
        'comment': sessionData['comment'] ?? '',
        'group_id': groupId // Note underscore
      };

      print('Sending data: ${json.encode(formattedData)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(formattedData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to create session (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Update a session
  static Future<Map<String, dynamic>> updateSession(int groupId,
      int sessionId, Map<String, dynamic> sessionData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/groups/$groupId/session/$sessionId'),
            headers: _headers,
            body: json.encode(sessionData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // Delete a session
  static Future<void> deleteSession(int sessionId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_sessionsUrl/$sessionId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // ========== STUDENTS ==========

  // Get all students
  static Future<List<dynamic>> getStudents() async {
    try {
      final response = await http
          .get(
            Uri.parse(_studentsUrl),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  // Get students by group
  //students/by-group/{groupId}
  static Future<List<dynamic>> getStudentsByGroup(int groupId) async {
    try {
      final url = '$_baseUrl/groups/$groupId/students';
      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  // Get a single student
  //students/by-group/{groupId}
  static Future<Map<String, dynamic>> getStudent(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_studentsUrl/$studentId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load student: $e');
    }
  }

  // Create a student
  static Future<Map<String, dynamic>> createStudent(
      Map<String, dynamic> studentData) async {
    try {
        final groupId = studentData['group_id'];
      final url = '$_baseUrl/groups/$groupId/students';


      // Ensure keys match your database columns exactly
      final formattedData = {
        'fname': studentData['fname'], // Must match DB column
        'name': studentData['name'],
        'email': studentData['email'] ,
      // Note underscore
      };

     print('Sending data: ${json.encode(formattedData)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(formattedData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to create student (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }


  // Update a student
  static Future<Map<String, dynamic>> updateStudent(int groupId,
      int studentId, Map<String, dynamic> studentData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/groups/$groupId/students/$studentId'),
            headers: _headers,
            body: json.encode(studentData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete a student
  static Future<void> deleteStudent(int studentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_studentsUrl/$studentId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Import students from an Excel/CSV file
  static Future<Map<String, dynamic>> importStudents(File file) async {
    try {
      // Create multipart request
      var request =
          http.MultipartRequest('POST', Uri.parse('$_studentsUrl/import'));

      // Add file to request
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Send request
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to import students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to import students: $e');
    }
  }

  // ========== ATTENDANCE ==========

  // Get attendance for a session
  static Future<List<dynamic>> getAttendanceBySession(int sessionId) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendance';
      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load attendance: $e');
    }
  }

  // Create attendance record
  static Future<Map<String, dynamic>> createAttendance(
      int sessionId, Map<String, dynamic> attendanceData) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendance';

      final formattedData = {
        'student_id': attendanceData['student_id'],
        'session_id': sessionId,
        'status': attendanceData['status'] ?? 'present', // Default status
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(formattedData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create attendance: $e');
    }
  }

  // Update attendance status
  static Future<Map<String, dynamic>> updateAttendance(int sessionId,
      int attendanceId, Map<String, dynamic> attendanceData) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendance/$attendanceId';
      final response = await http
          .put(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(attendanceData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Delete attendance record
  static Future<void> deleteAttendance(int sessionId, int attendanceId) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendance/$attendanceId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }

  // Bulk create attendance records
  static Future<Map<String, dynamic>> bulkCreateAttendance(
      int sessionId, List<Map<String, dynamic>> attendanceList) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendance/bulk';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode({'attendance': attendanceList}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create bulk attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create bulk attendance: $e');
    }
  }

  // ========== RESPONSE HANDLERS ==========

  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return response.body.isNotEmpty ? json.decode(response.body) : [];
      case 400:
        throw Exception('Bad request');
      case 401:
      case 403:
        throw Exception('Unauthorized');
      case 404:
        throw Exception('Not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception(
            'Status: ${response.statusCode}\nBody: ${response.body}');
    }
  }

  static dynamic _handleGroupResponse(http.Response response) {
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) {
          return data;
        }
        throw Exception('Expected List in "data" field');
      }

      throw Exception('Unexpected response format');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
}
