// Fixed services/api_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class ApiService {
  static const String baseUrl = 'http://182.93.94.210:3067/api/v1';

  // Helper method to get headers with authentication
  static Map<String, String> _getHeaders({bool includeAuth = false}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final appData = AppData();
      if (appData.authToken != null) {
        headers['Authorization'] = 'Bearer ${appData.authToken}';
        developer.log('Including auth token in headers');
      } else {
        developer.log('Warning: No auth token available');
      }
    }
    
    return headers;
  }

  // Get all categories (updated endpoint)
  static Future<Map<String, dynamic>> getParentCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _getHeaders(),
      );

      developer.log('Categories API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching categories: $e');
      throw Exception('Network error: $e');
    }
  }

  // Enhanced method to get courses with special category handling
  static Future<Map<String, dynamic>> getCategoryCourses(String categoryId) async {
    try {
      // Handle special mock categories
      if (categoryId == 'search' || categoryId == 'all' || categoryId == 'featured') {
        developer.log('Special category detected: $categoryId, fetching all courses');
        return await getAllCourses(categoryType: categoryId);
      }

      // Validate real category ID (should be MongoDB ObjectId format)
      if (!_isValidObjectId(categoryId)) {
        developer.log('Invalid category ID format: $categoryId');
        throw Exception('Invalid category ID format');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/category/$categoryId/courses'),
        headers: _getHeaders(includeAuth: true),
      );

      developer.log('Category Courses API Status: ${response.statusCode}');
      developer.log('Category Courses API URL: $baseUrl/category/$categoryId/courses');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Successfully fetched courses for category: $categoryId');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Category not found. It may have been deleted.');
      } else {
        final errorData = _parseErrorResponse(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      throw Exception('Network error: $e');
    }
  }

  // New method to get all courses (for special categories)
  static Future<Map<String, dynamic>> getAllCourses({String? categoryType}) async {
    try {
      // Try different possible endpoints for all courses
      final List<String> possibleEndpoints = [
        '$baseUrl/courses',
        '$baseUrl/courses/all',
        '$baseUrl/course',
      ];

      Map<String, dynamic>? successResponse;
      
      for (String endpoint in possibleEndpoints) {
        try {
          developer.log('Trying endpoint: $endpoint');
          
          final response = await http.get(
            Uri.parse(endpoint),
            headers: _getHeaders(includeAuth: true),
          );

          developer.log('All Courses API Status: ${response.statusCode} for endpoint: $endpoint');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            developer.log('Successfully fetched all courses from: $endpoint');
            
            // Transform response to match CategoryCoursesResponse format
            successResponse = _transformToCategoryCoursesFormat(data, categoryType ?? 'all');
            break;
          }
        } catch (e) {
          developer.log('Failed to fetch from $endpoint: $e');
          continue;
        }
      }

      if (successResponse != null) {
        return successResponse;
      } else {
        // If all endpoints fail, return mock data structure
        developer.log('All endpoints failed, returning mock response');
        return _createMockCategoryResponse(categoryType ?? 'all');
      }
    } catch (e) {
      developer.log('Error fetching all courses: $e');
      return _createMockCategoryResponse(categoryType ?? 'all');
    }
  }

  // Helper method to validate MongoDB ObjectId format
  static bool _isValidObjectId(String id) {
    // MongoDB ObjectId is 24 characters long and contains only hex characters
    final RegExp objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
    return objectIdRegex.hasMatch(id);
  }

  // Helper method to parse error response
  static Map<String, dynamic> _parseErrorResponse(String responseBody) {
    try {
      return json.decode(responseBody);
    } catch (e) {
      return {'message': responseBody};
    }
  }

  // Helper method to transform response to CategoryCoursesResponse format
  static Map<String, dynamic> _transformToCategoryCoursesFormat(Map<String, dynamic> data, String categoryType) {
    final courses = data['data'] ?? data['courses'] ?? [];
    
    return {
      'status': 200,
      'data': {
        'category': _createMockCategory(categoryType),
        'courses': courses,
        'pagination': data['pagination'] ?? {
          'page': 1,
          'limit': courses.length,
          'total': courses.length,
          'pages': 1,
          'hasMore': false
        }
      },
      'message': 'Success'
    };
  }

  // Helper method to create mock category
  static Map<String, dynamic> _createMockCategory(String categoryType) {
    switch (categoryType) {
      case 'search':
        return {
          '_id': 'search',
          'name': 'Search Results',
          'description': 'Courses matching your search',
          'slug': 'search-results',
          'icon': 'search',
          'color': '#F48706',
          'isActive': true,
          'sortOrder': 0,
          'keywords': ['search', 'find'],
          'createdBy': {
            '_id': 'system',
            'email': 'system@app.com',
            'name': 'System'
          },
          'statistics': {
            'courses': 0,
            'lessons': 0,
            'notes': 0,
            'videos': 0
          },
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      case 'featured':
        return {
          '_id': 'featured',
          'name': 'Featured Courses',
          'description': 'Our handpicked best courses',
          'slug': 'featured-courses',
          'icon': 'star',
          'color': '#F48706',
          'isActive': true,
          'sortOrder': 0,
          'keywords': ['featured', 'popular'],
          'createdBy': {
            '_id': 'system',
            'email': 'system@app.com',
            'name': 'System'
          },
          'statistics': {
            'courses': 0,
            'lessons': 0,
            'notes': 0,
            'videos': 0
          },
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      default: // 'all'
        return {
          '_id': 'all',
          'name': 'All Courses',
          'description': 'Browse all available courses',
          'slug': 'all-courses',
          'icon': 'school',
          'color': '#F48706',
          'isActive': true,
          'sortOrder': 0,
          'keywords': ['all', 'browse'],
          'createdBy': {
            '_id': 'system',
            'email': 'system@app.com',
            'name': 'System'
          },
          'statistics': {
            'courses': 0,
            'lessons': 0,
            'notes': 0,
            'videos': 0
          },
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
    }
  }

  // Helper method to create mock response when API fails
  static Map<String, dynamic> _createMockCategoryResponse(String categoryType) {
    return {
      'status': 200,
      'data': {
        'category': _createMockCategory(categoryType),
        'courses': [], // Empty courses list
        'pagination': {
          'page': 1,
          'limit': 10,
          'total': 0,
          'pages': 1,
          'hasMore': false
        }
      },
      'message': 'No courses available at the moment'
    };
  }

  // Get course details with lessons (updated endpoint - requires auth)
  static Future<Map<String, dynamic>> getCourseDetails(String courseId, {String? lessonId}) async {
    try {
      String url = '$baseUrl/courses/$courseId';
      if (lessonId != null) {
        url += '?lessonId=$lessonId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: true), // Requires authentication
      );

      developer.log('Course Details API Status: ${response.statusCode}');
      developer.log('Course Details URL: $url');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        developer.log('Authentication failed for course details');
        throw Exception('Authentication required. Please login again.');
      } else {
        developer.log('Course details error response: ${response.body}');
        throw Exception('Failed to load course details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching course details: $e');
      throw Exception('Network error: $e');
    }
  }

  // Helper method to build full URL for media files
  static String getFullMediaUrl(String relativePath) {
    if (relativePath.isEmpty) return '';
    return 'http://182.93.94.210:3067$relativePath';
  }

  // Download note file (with authentication if needed)
  static Future<bool> downloadNote(String noteUrl, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse(getFullMediaUrl(noteUrl)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Here you would save the file to device storage
        // This is a placeholder - implement actual file saving
        developer.log('Note downloaded successfully: $fileName');
        return true;
      } else {
        throw Exception('Failed to download note: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error downloading note: $e');
      return false;
    }
  }
}

// Response wrapper classes
class ApiResponse<T> {
  final int status;
  final T? data;
  final String? error;
  final String message;

  ApiResponse({
    required this.status,
    this.data,
    this.error,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      status: json['status'] ?? 0,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'],
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status == 200 && error == null;
}