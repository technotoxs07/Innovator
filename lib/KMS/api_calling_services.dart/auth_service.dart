// import 'dart:async';
// import 'dart:developer';
// import 'package:innovator/KMS/core/constants/api_constants.dart';
// import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
// import 'package:innovator/KMS/core/constants/network/dio_client.dart';
// import 'package:innovator/KMS/core/constants/service/token_service.dart';

// class AuthService extends BaseApiService {
//   AuthService() : super(dio: DioClient.authInstance);

//   final TokenService _tokenService = TokenService();
//   Future<void> logout() async {
//     await _tokenService.clearTokens();
//     log("Logging Out:${_tokenService.clearTokens()}");
//   }

//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     return await post(
//       ApiConstants.login,
//       data: {'email': email, 'password': password},
//     );
//   }

//   Future<Map<String, dynamic>> register({
//     required String userName,
//     required String email,
//     required String password,
//     required String role,
//   }) async {
//     return await post(
//       ApiConstants.register,

//       data: {
//         'username': userName,
//         'email': email,
//         'password': password,
//         'role': role,
//       },
//     );
//   }
// }



import 'dart:developer';

import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/core/constants/service/token_service.dart';

class AuthService extends BaseApiService {
  AuthService() : super(dio: DioClient.authInstance);

  final TokenService _tokenService = TokenService();

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Returns the full response map.
  /// Tokens are saved automatically by [AppInterceptor._autoSaveToken].
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String userName,
    required String email,
    required String password,
    required String role,
  }) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'username': userName,
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _tokenService.clearTokens();
    DioClient.reset(); // Reset Dio so stale tokens are not reused
    log('✅ Logged out — tokens cleared and Dio reset');
  }

  // ─── Auth State ───────────────────────────────────────────────────────────

  /// Returns true if a valid access token exists in storage.
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  //   Future<Map<String, dynamic>> forgotPassword({required String email}) async {
  //   return await post(ApiConstants.forgotPassword, data: {'email': email});
  // }

  // Future<Map<String, dynamic>> validateCode({
  //   required String email,
  //   required String resetCode,
  //   required String newPassword,
  // }) async {
  //   return await post(
  //     ApiConstants.validateResetCode,
  //     data: {'email': email, 'resetCode': resetCode, 'newPassword': newPassword},
  //   );
  // }

  // Future<Map<String, dynamic>> resentCode({required String email}) async {
  //   return await post(ApiConstants.resendCode, data: {'email': email});
  // }

  // Future<Map<String, dynamic>> changePassword({
  //   required String currentPassword,
  //   required String newPassword,
  //   required String confirmPassword,
  // }) async {
  //   return await post(
  //     ApiConstants.changePassword,
  //     data: {
  //       'currentPassword': currentPassword,
  //       'newPassword': newPassword,
  //       'confirmPassword': confirmPassword,
  //     },
  //   );
  // }
}