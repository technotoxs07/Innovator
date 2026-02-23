//  import 'package:dio/dio.dart'; 
// import 'dio_client.dart';

// abstract class BaseApiService {
//   final Dio _dio;
//   BaseApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

//   // GET request - simplified, no error handling needed
//   Future<T> get<T>(
//     String endpoint, {
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     final response = await _dio.get(
//       endpoint,
//       queryParameters: queryParameters,
//       options: options,
//     );
//     return response.data as T;
//   }

//   // POST request - simplified, no error handling needed
//   Future<T> post<T>(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     final response = await _dio.post(
//       endpoint,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
//     return response.data as T;
//   }

//   // PUT request - simplified
//   Future<T> put<T>(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     final response = await _dio.put(
//       endpoint,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
//     return response.data as T;
//   }

//   // DELETE request - simplified
//   Future<T> delete<T>(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     final response = await _dio.delete(
//       endpoint,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
//     return response.data as T;
//   }

//   // PATCH request - simplified
//   Future<T> patch<T>(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     final response = await _dio.patch(
//       endpoint,
//       data: data,
//       queryParameters: queryParameters,
//       options: options,
//     );
//     return response.data as T;
//   }

//   // Upload file - simplified
//   Future<T> upload<T>(
//     String endpoint,
//     FormData formData, {
//     ProgressCallback? onSendProgress,
//   }) async {
//     final response = await _dio.post(
//       endpoint,
//       data: formData,
//       onSendProgress: onSendProgress,
//       options: Options(
//         headers: {'Content-Type': 'multipart/form-data'},
//       ),
//     );
//     return response.data as T;
//   }
// }

import 'package:dio/dio.dart';
import 'dio_client.dart';

/// Base class for all API services.
/// Handles the raw HTTP calls — error handling is done inside [AppInterceptor].
abstract class BaseApiService {
  final Dio _dio;

  BaseApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ─── GET ──────────────────────────────────────────────────────────────────

  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // ─── POST ─────────────────────────────────────────────────────────────────

  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // ─── PUT ──────────────────────────────────────────────────────────────────

  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // ─── PATCH ────────────────────────────────────────────────────────────────

  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // ─── UPLOAD ───────────────────────────────────────────────────────────────

  Future<T> upload<T>(
    String endpoint,
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    final response = await _dio.post(
      endpoint,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    return response.data as T;
  }
}