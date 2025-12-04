import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Base URL de la API
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:5112/api';
  static String get fileServerUrl => dotenv.env['FILESERVER_URL'] ?? 'http://localhost:5113/api';
  
  // Ambiente actual
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  
  // Timeout de la API
  static int get apiTimeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  
  // Helper para saber si estamos en desarrollo
  static bool get isDevelopment => environment == 'development';
  
  // Helper para saber si estamos en producción
  static bool get isProduction => environment == 'production';
}