/// SENTINEL Mobile App — Configuration
/// Canon: idea.md, Flutter_Agent.md §6

class AppConfig {
  // Dev URLs (local backend)
  static const String devBaseUrl = 'http://localhost:8001';
  static const String devWsUrl = 'ws://localhost:8001';

  // Production URLs (Railway deployment)
  static const String prodBaseUrl = 'https://sentinelai-production-e7d5.up.railway.app';
  static const String prodWsUrl = 'wss://sentinelai-production-e7d5.up.railway.app';

  // Toggle for dev vs prod
  static const bool isProduction = true;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  static String get wsUrl => isProduction ? prodWsUrl : devWsUrl;

  static String get apiBase => '$baseUrl/api/v1';
  static String wsRunUrl(String runId) => '$wsUrl/ws/runs/$runId';
}
