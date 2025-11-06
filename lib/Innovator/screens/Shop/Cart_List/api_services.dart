// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/models/Shop_cart_model.dart';

class ApiService {
  
  static const String baseUrl = 'http://182.93.94.210:3067/api/v1';
  final AppData appData = AppData();

  Future<CartListResponse> getCartList() async {
    final url = Uri.parse('$baseUrl/list-carts');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${appData.authToken}',
      },
    );

    if (response.statusCode == 200) {
      return CartListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load cart list: ${response.statusCode}');
    }
  }

  Future<void> deleteCartItem(String itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-cart/$itemId'),
      headers: {
        'authorization': 'Bearer ${appData.authToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete cart item');
    }
  }

  // Fixed checkout method with multiple field name approaches
// Fixed checkout method with proper JSON encoding for customerInfo
// Fixed checkout method with proper JSON encoding for customerInfo
Future<CheckoutResponse> checkout({
  required CustomerInfo customerInfo,
  required double paidAmount,
  required File paymentProof,
  String? notes,
}) async {
  try {
    final url = Uri.parse('$baseUrl/checkout');
    
    // Validate file exists and is readable
    if (!await paymentProof.exists()) {
      throw Exception('Payment proof file does not exist');
    }

    // Check file size (limit to 10MB)
    final fileSize = await paymentProof.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('File size too large. Maximum 10MB allowed.');
    }

    // Detect MIME type properly
    final mimeType = lookupMimeType(paymentProof.path);
    debugPrint('Detected MIME type: $mimeType');
    
    if (mimeType == null || !_isValidImageMimeType(mimeType)) {
      throw Exception('Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed.');
    }

    // Create multipart request
    var request = http.MultipartRequest('POST', url);
    
    // Add headers
    request.headers.addAll({
      'authorization': 'Bearer ${appData.authToken}',
      'Accept': 'application/json',
    });

    // SOLUTION: Send each customerInfo field separately with a specific naming convention
    // that your backend can reconstruct into an object
    request.fields['customerName'] = customerInfo.name;
    request.fields['customerPhone'] = customerInfo.phone;
    request.fields['customerAddress'] = customerInfo.address;
    request.fields['paidAmount'] = paidAmount.toString();
    
    if (notes != null && notes.isNotEmpty) {
      request.fields['notes'] = notes;
    }

    // Add payment proof file with proper content type
    final multipartFile = await http.MultipartFile.fromPath(
      'paymentProof',
      paymentProof.path,
      contentType: MediaType.parse(mimeType),
    );
    
    request.files.add(multipartFile);

    debugPrint('Sending request to: $url');
    debugPrint('Request fields: ${request.fields}');
    debugPrint('File name: ${paymentProof.path.split('/').last}');
    debugPrint('File size: ${fileSize} bytes');
    debugPrint('Authorization header present: ${request.headers.containsKey('authorization')}');

    // Send request with timeout
    final streamedResponse = await request.send().timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout. Please check your internet connection.');
      },
    );
    
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        // Check if response is JSON 
        if (response.headers['content-type']?.contains('application/json') == true) {
          return CheckoutResponse.fromJson(json.decode(response.body));
        } else {
          throw Exception('Server returned non-JSON response: ${response.body}');
        }
      } catch (e) {
        throw Exception('Failed to parse successful response: $e');
      }
    } else {
      // Handle error responses
      String errorMessage = 'Checkout failed with status ${response.statusCode}';
      
      try {
        // Check if it's an HTML error page
        if (response.body.contains('<!DOCTYPE html>')) {
          // Extract error message from HTML
          final RegExp errorRegex = RegExp(r'<pre>(.*?)</pre>', dotAll: true);
          final match = errorRegex.firstMatch(response.body);
          if (match != null) {
            String htmlError = match.group(1) ?? '';
            // Clean up HTML entities and formatting
            htmlError = htmlError
                .replaceAll('<br>', '\n')
                .replaceAll('&nbsp;', ' ')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
            errorMessage = htmlError.split('\n').first; // Get just the first line
          }
        } else {
          // Try to parse as JSON
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error']?['error'] ?? errorMessage;
        }
      } catch (e) {
        // If parsing fails, use response body if it's short enough
        if (response.body.isNotEmpty && response.body.length < 500) {
          errorMessage = response.body;
        }
      }
      
      throw Exception(errorMessage);
    }
  } catch (e) {
    if (e.toString().contains('Checkout error:')) {
      rethrow; // Don't double-wrap
    }
    throw Exception('Checkout error: ${e.toString()}');
  }
}

  // Helper method to validate image MIME types
  bool _isValidImageMimeType(String mimeType) {
    const validTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
    ];
    return validTypes.contains(mimeType.toLowerCase());
  }
}