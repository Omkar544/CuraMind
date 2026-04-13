import 'dart:io';

class ApiConfig {
  /// 🌐 LAPTOP IP ADDRESS (Hotspot / Wi-Fi IPv4)
  /// Updated based on detected IP: 172.20.10.5
  static const String serverIp = '172.20.10.5';
  static const String port = '8000';

  /// 🏠 Root URL (e.g., for health checks or favicon)
  static String get rootUrl => 'http://$serverIp:$port';

  /// 🚀 Base API URL (The prefix used by all FastAPI routers)
  static String get baseUrl => '$rootUrl/api';

  // --- 🧩 MODULE SPECIFIC ENDPOINTS ---

  /// Auth: Login, Register, Profile Management
  static String get authUrl => '$baseUrl/auth';

  /// LifeLog Hub: History Timeline & Vision Scan storage
  static String get lifeLogUrl => '$baseUrl/lifelog';

  /// MindEase: PHQ-9, GAD-7, and Sentiment Analysis
  static String get mindEaseUrl => '$baseUrl/mindease';

  /// CareClock: Medicine and Appointment Scheduling
  static String get careClockUrl => '$baseUrl/careclock';

  /// DailyMoves: XGBoost ML Predictions
  static String get dailyMovesUrl => '$baseUrl/dailymoves';

  /// 📲 Device-Specific Logic
  /// Returns the mandatory laptop IP for physical device (CPH2269) connectivity.
  static String get smartBaseUrl => baseUrl;
}
