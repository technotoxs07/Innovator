 

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:innovator/KMS/core/constants/service/connectivity_service.dart';
import 'package:innovator/KMS/core/constants/service/token_service.dart';
import 'package:innovator/KMS/core/exceptions/app_exceptions.dart';
import 'package:innovator/KMS/core/utils/toast_utils.dart'; 

class AppInterceptor extends Interceptor {
  final TokenService _tokenService = TokenService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // ✅ Define auth endpoints that return tokens
  static const _authEndpoints = ['/Auth/login', '/Auth/signup', '/Auth/register'];

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    
    if (!_connectivityService.isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: NetworkException(),
          type: DioExceptionType.connectionError,
        ),
      );
    }

    // ✅ Only add token for non-auth endpoints
    final isAuthEndpoint = _authEndpoints.any((endpoint) => 
      options.path.toLowerCase().contains(endpoint.toLowerCase())
    );
    
    if (!isAuthEndpoint) {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    log('🚀 REQUEST[${options.method}] => ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    log('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
    
    // ✅ Auto-save token from login/signup responses
    await _autoSaveToken(response);
    
    if (_shouldShowSuccessToast(response)) {
      final message = _extractMessage(response.data) ?? 'Success';
      ToastUtils.showSuccess(message);
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('❌ ERROR[${err.response?.statusCode}] => ${err.requestOptions.path}');

    final exception = _handleError(err);
    
    // Always show error toast
    ToastUtils.showError(exception.message);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  // ✅ NEW: Automatically save token from auth responses
  Future<void> _autoSaveToken(Response response) async {
    try {
      // Check if this is an auth endpoint response
      final isAuthEndpoint = _authEndpoints.any((endpoint) => 
        response.requestOptions.path.toLowerCase().contains(endpoint.toLowerCase())
      );
      
      if (!isAuthEndpoint) return;
      
      // Check if response contains a token
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        
        if (token != null && token.isNotEmpty) {
          log('💾 Auto-saving token from ${response.requestOptions.path}');
          await _tokenService.saveTokens(
            accessToken: token,
            refreshToken: refreshToken,
          );
          log('✅ Token saved successfully');
        }
      }
    } catch (e) {
      log('⚠️ Failed to auto-save token: $e');
      // Don't throw - let the response continue
    }
  }

  AppException _handleError(DioException error) {
    if (!_connectivityService.isConnected) {
      return NetworkException();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response);

      case DioExceptionType.cancel:
        return AppException('Request cancelled');

      default:
        return AppException('Something went wrong. Please try again.');
    }
  }

  AppException _handleStatusCode(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;
    final message = _extractMessage(data);

    switch (statusCode) {
      case 400:
        return BadRequestException(message ?? 'Invalid request');
      case 401:
        _handleUnauthorized();
        return UnauthorizedException(message ?? 'Session expired');
      case 403:
        return AppException(message ?? 'Access denied', statusCode: 403);
      case 404:
        return NotFoundException(message ?? 'Resource not found');
      case 422:
        return AppException(message ?? 'Validation failed', statusCode: 422);
      case 500:
      case 502:
      case 503:
        return ServerException(message ?? 'Server error');
      default:
        return AppException(
          message ?? 'Error occurred (Code: $statusCode)',
          statusCode: statusCode,
        );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['message'] ?? data['error'] ?? data['msg'] ?? data['detail'];
    }

    return data.toString();
  }

  bool _shouldShowSuccessToast(Response response) {
    final method = response.requestOptions.method;
    return ['POST', 'PUT', 'DELETE', 'PATCH'].contains(method);
  }

  void _handleUnauthorized() async {
    await _tokenService.clearTokens();
  }
}