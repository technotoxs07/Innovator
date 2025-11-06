// api_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/InnovatorApp_data/App_data.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'http://182.93.94.210:3067/api/v1';
  
  // Get headers with auth token from AppData
  static Map<String, String> get headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final appData = AppData();
    if (appData.authToken != null && appData.authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${appData.authToken}';
      developer.log('Using auth token: ${appData.authToken!.substring(0, 20)}...');
    } else {
      developer.log('No auth token available');
    }
    
    return headers;
  }

  // Helper to get full media URL
  static String getFullMediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'http://182.93.94.210:3067/$cleanPath';
  }

  // Get all courses
  static Future<Map<String, dynamic>> getCourses({
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/courses?page=$page&limit=$limit');
      developer.log('Fetching courses from: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      developer.log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched ${data['data']?['courses']?.length ?? 0} courses');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      rethrow;
    }
  }

  // Get course details
  static Future<Map<String, dynamic>> getCourseDetails(String courseId, {String? lessonId}) async {
    try {
      String url = '$baseUrl/courses/$courseId';
      if (lessonId != null) {
        url += '?lessonId=$lessonId';
      }
      
      developer.log('Fetching course details from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      developer.log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched course details');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else if (response.statusCode == 404) {
        throw Exception('Course not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load course details');
      }
    } catch (e) {
      developer.log('Error fetching course details: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      rethrow;
    }
  }

  // Get parent categories
  static Future<Map<String, dynamic>> getParentCategories() async {
    try {
      final url = Uri.parse('$baseUrl/categories/parent');
      developer.log('Fetching parent categories from: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      developer.log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched parent categories');
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      developer.log('Error fetching parent categories: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      rethrow;
    }
  }

  // Get subcategories
  static Future<Map<String, dynamic>> getSubcategories(String parentId) async {
    try {
      final url = Uri.parse('$baseUrl/categories/subcategories/$parentId');
      developer.log('Fetching subcategories from: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      developer.log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched subcategories');
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load subcategories');
      }
    } catch (e) {
      developer.log('Error fetching subcategories: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      rethrow;
    }
  }

  // Search courses
  static Future<Map<String, dynamic>> searchCourses({
    required String query,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/courses/search?q=$query&page=$page&limit=$limit');
      developer.log('Searching courses: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Search returned ${data['data']?['courses']?.length ?? 0} courses');
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Search failed');
      }
    } catch (e) {
      developer.log('Error searching courses: $e');
      rethrow;
    }
  }

  // Enroll in course
  static Future<Map<String, dynamic>> enrollInCourse(String courseId) async {
    try {
      final appData = AppData();
      if (!appData.isAuthenticated) {
        throw Exception('Please login to enroll in courses');
      }

      final url = Uri.parse('$baseUrl/courses/$courseId/enroll');
      developer.log('Enrolling in course: $url');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        developer.log('Successfully enrolled in course');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to enroll');
      }
    } catch (e) {
      developer.log('Error enrolling in course: $e');
      rethrow;
    }
  }

  // Get enrolled courses
  static Future<Map<String, dynamic>> getEnrolledCourses({
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final appData = AppData();
      if (!appData.isAuthenticated) {
        throw Exception('Please login to view enrolled courses');
      }

      final url = Uri.parse('$baseUrl/courses/enrolled?page=$page&limit=$limit');
      developer.log('Fetching enrolled courses: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched enrolled courses');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load enrolled courses');
      }
    } catch (e) {
      developer.log('Error fetching enrolled courses: $e');
      rethrow;
    }
  }

  // Mark lesson as complete
  static Future<Map<String, dynamic>> markLessonComplete(
    String courseId,
    String lessonId,
  ) async {
    try {
      final appData = AppData();
      if (!appData.isAuthenticated) {
        throw Exception('Please login to track progress');
      }

      final url = Uri.parse('$baseUrl/courses/$courseId/lessons/$lessonId/complete');
      developer.log('Marking lesson as complete: $url');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        developer.log('Successfully marked lesson as complete');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update progress');
      }
    } catch (e) {
      developer.log('Error marking lesson complete: $e');
      rethrow;
    }
  }

  // Get course progress
  static Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    try {
      final appData = AppData();
      if (!appData.isAuthenticated) {
        throw Exception('Please login to view progress');
      }

      final url = Uri.parse('$baseUrl/courses/$courseId/progress');
      developer.log('Fetching course progress: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched course progress');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load progress');
      }
    } catch (e) {
      developer.log('Error fetching course progress: $e');
      rethrow;
    }
  }

  // Download course material
  static Future<Map<String, dynamic>> downloadMaterial(
    String courseId,
    String materialId,
  ) async {
    try {
      final appData = AppData();
      if (!appData.isAuthenticated) {
        throw Exception('Please login to download materials');
      }

      final url = Uri.parse('$baseUrl/courses/$courseId/materials/$materialId/download');
      developer.log('Downloading material: $url');
      
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        // Return download URL or binary data
        return {
          'status': 200,
          'data': response.bodyBytes,
          'message': 'Download successful'
        };
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to download');
      }
    } catch (e) {
      developer.log('Error downloading material: $e');
      rethrow;
    }
  }
}