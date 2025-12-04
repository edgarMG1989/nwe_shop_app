import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';

class ProductoService {
  static Future<List<dynamic>> getProductosNovedad({
    bool forceRefresh = false,
  }) async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/novedades";

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

  static Future<List<dynamic>> getProductoInventario(int id) async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/inventario";

      final response = await http.get(
        Uri.parse(
          "$url?idProducto=$id&nocache=${DateTime.now().millisecondsSinceEpoch}",
        ),
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
      throw Exception('Error al cargar inventario: $e');
    }
  }

  static Future<List<dynamic>> getProductoGenero(int idGenero) async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/genero";

      final response = await http
          .get(
            Uri.parse(
              "$url?idGenero=$idGenero&nocache=${DateTime.now().millisecondsSinceEpoch}",
            ),
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
          )
          .timeout(Duration(milliseconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al cargar genero: $e');
    }
  }

  static Future<List<dynamic>> getProductoAll() async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/all";

      final response = await http
          .get(
            Uri.parse("$url?nocache=${DateTime.now().millisecondsSinceEpoch}"),
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
          )
          .timeout(Duration(milliseconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al cargar genero: $e');
    }
  }

  static Future<Map<String, dynamic>> addProducto(
    Map<String, dynamic> item,
  ) async {
    try {
      item['inventarioJson'] = jsonEncode(item['inventarioJson']);
      item['generosJson'] = jsonEncode(item['generosJson']);

      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/productos/postAgregarProducto"),
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

  static Future<Map<String, dynamic>> selProductoId(int idProducto) async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/getProductoId";

      final response = await http.get(
        Uri.parse(
          "$url?idProducto=$idProducto&nocache=${DateTime.now().millisecondsSinceEpoch}",
        ),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          "success": 1,
          "producto": responseData[0][0], // ✅ Primer recordset → producto
          "inventario": responseData[1], // ✅ Segundo → tallas
          "generos": responseData[2], // ✅ Tercero → géneros
        };
      }

      return {"success": 0, "message": "Error en la petición"};
    } catch (e) {
      return {"success": 0, "message": "Error inesperado: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateProducto(
    Map<String, dynamic> item,
  ) async {
    try {
      item['inventarioJson'] = jsonEncode(item['inventarioJson']);
      item['generosJson'] = jsonEncode(item['generosJson']);

      final response = await http.put(
        Uri.parse("${EnvConfig.baseUrl}/productos/putEditarProducto"),
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

  static Future<Map<String, dynamic>> deleteProducto(int idProducto) async {
    try {
      final response = await http.delete(
        Uri.parse("${EnvConfig.baseUrl}/productos/deleteEliminarProducto"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"idProducto": idProducto}),
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

  static Future<String?> generate(
    File userImage,
    File garmentFile,
    String descripcion,
  ) async {
    final uri = Uri.parse("${EnvConfig.baseUrl}/productos/tryon");

    var request = http.MultipartRequest("POST", uri)
      ..files.add(
        await http.MultipartFile.fromPath("userImage", userImage.path),
      )
      ..files.add(
        await http.MultipartFile.fromPath("garmentImage", garmentFile.path),
      )
      ..fields["description"] = descripcion;

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    final json = jsonDecode(respStr);
    return json["image"];
  }
}
