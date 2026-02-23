 
//  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class TokenService {
//   static final TokenService _instance = TokenService._internal();
//   factory TokenService() => _instance;
//   TokenService._internal();

//   final _storage = FlutterSecureStorage();
  
//   static const String _accessTokenKey = 'access_token';
//   static const String _refreshTokenKey = 'refresh_token';

//   Future<void> saveTokens({
//     required String accessToken,
//     String? refreshToken,
//   }) async {
//     await _storage.write(key: _accessTokenKey, value: accessToken);
//     if (refreshToken != null) {
//       await _storage.write(key: _refreshTokenKey, value: refreshToken);
//     }
//   }

//   Future<String?> getAccessToken() async {
//     return await _storage.read(key: _accessTokenKey);
//   }

//   Future<String?> getRefreshToken() async {
//     return await _storage.read(key: _refreshTokenKey);
//   }

//   Future<void> clearTokens() async {
//     await _storage.delete(key: _accessTokenKey);
//     await _storage.delete(key: _refreshTokenKey);
//   }

//   Future<bool> hasToken() async {
//     final token = await getAccessToken();
//     return token != null && token.isNotEmpty;
//   }
// }


import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  final _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}