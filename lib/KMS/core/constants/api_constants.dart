class ApiConstants {
  //Auth Base Url

  static String get authBaseUrl => 'http://182.93.94.220:8010/api';
    static String get baseUrl => 'http://182.93.94.220:8002/api';


  //auth EndPoints
  static String get register => '$authBaseUrl/auth/register/';
  static String get login => '$authBaseUrl/auth/sso/login/';
  //profile data
  static String get myProfile => '$baseUrl/auth/user/me';

  //teacher endpoints
  static String get teacherProfile => '$baseUrl/teacher/profile/';
  static String get teacherKyc => '$baseUrl/teacher/kyc/upload/';
  static String get teacherCheckIn => '$baseUrl/teacher/attendance/check-in/';
  static String get teacherCheckOut =>
      '$baseUrl/teacher/attendance/9/check-out/';
  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
