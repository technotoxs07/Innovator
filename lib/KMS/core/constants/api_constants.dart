class ApiConstants {
  // Base Url
  // static String get baseUrl => 'http://192.168.1.85:8000/api';
 static String get baseUrl=> 'https://unerratic-stanford-rimosely.ngrok-free.dev/api';

  //auth EndPoints
  static String get register => '$baseUrl/auth/register/';
  static String get login => '$baseUrl/auth/sso/login/';
  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
