import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class VentaService {
  static Future<Map<String, dynamic>> intencionPago(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/venta/postCreaIntencion"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {"success": 0, "message": "Error inesperado: $e"};
    }
  }

  static Future<List<dynamic>> getVentaIdUsuario(idUsuario) async {
    try {
      final url = "${EnvConfig.baseUrl}/venta/getVentaIdUsuario";

      final response = await http.get(
        Uri.parse("$url?idUsuario=$idUsuario&nocache=${DateTime.now().millisecondsSinceEpoch}"),
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
      throw Exception('Error al cargar productos: $e');
    }
  }

   static Future<List<dynamic>> getVentas() async {
    try {
      final url = "${EnvConfig.baseUrl}/venta/getVentas";

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
      throw Exception('Error al cargar productos: $e');
    }
  }

  static Future<Map<String, dynamic>> addVenta(
    Map<String, dynamic> item,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/venta/postAgregaVenta"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          "success": responseData[0]['success'],
          "message": responseData[0]['message'],
        };
      }

      return {"success": 0, "message": "Error en la petición"};
    } catch (e) {
      return {"success": 0, "message": "Error inesperado: $e"};
    }
  }

  static Future<Map<String, dynamic>> actualizarEstatus(
    int idVenta,
    int selectedStatus,
    int idUsuario
  ) async {
    try {

      final body = {
        "idVenta": idVenta,
        "idEstatus": selectedStatus,
        "idUsuario": idUsuario

      };
     
      final response = await http.put(
        Uri.parse("${EnvConfig.baseUrl}/venta/putActualizaEstatus"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          "success": responseData[0]['success'],
          "message": responseData[0]['message'],
        };
      }

      return {"success": 0, "message": "Error en la petición"};
    } catch (e) {
      return {"success": 0, "message": "Error inesperado: $e"};
    }
  }
}
