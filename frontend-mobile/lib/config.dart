/// SENTINEL Mobile App — Configuration
/// Canon: idea.md, Flutter_Agent.md §6

class AppConfig {
  // Dev URLs (local backend)
  static const String devBaseUrl = 'http://localhost:8001';
  static const String devWsUrl = 'ws://localhost:8001';

  // Production URLs (Render deployment)
  static const String prodBaseUrl = 'https://sentinel-api.onrender.com';
  static const String prodWsUrl = 'wss://sentinel-api.onrender.com';

  // Toggle for dev vs prod
  static const bool isProduction = false;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  static String get wsUrl => isProduction ? prodWsUrl : devWsUrl;

  static String get apiBase => '$baseUrl/api/v1';
  static String wsRunUrl(String runId) => '$wsUrl/ws/runs/$runId';
}
