class AppConfig {
  static const String baseUrl = 'https://dec-hrmproject.onrender.com';

  // You can add other configuration variables here as needed
  // For example:
  // static const String apiEndpoint = '/api/v1';

  static String getApiUrl(String path) {
    return '$baseUrl/$path';
  }
}