import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';

class CatalogoService {
  static Future<List<dynamic>> getTallas({bool forceRefresh = false}) async {
    try {
      final url = "${EnvConfig.baseUrl}/catalogo/getTallas";

      final response = await http.get(
        Uri.parse("$url?nocache=${DateTime.now().millisecondsSinceEpoch}"),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al cargar tallas: $e');
    }
  }

  static Future<List<dynamic>> getGeneros({bool forceRefresh = false}) async {
    try {
      final url = "${EnvConfig.baseUrl}/catalogo/getGeneros";

      final response = await http.get(
        Uri.parse("$url?nocache=${DateTime.now().millisecondsSinceEpoch}"),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al cargar generos: $e');
    }
  }

  static Future<List<dynamic>> getTipoPrenda({bool forceRefresh = false}) async {
    try {
      final url = "${EnvConfig.baseUrl}/catalogo/getTipoPrenda";

      final response = await http.get(
        Uri.parse("$url?nocache=${DateTime.now().millisecondsSinceEpoch}"),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al cargar tipos de prendas: $e');
    }
  }
}
