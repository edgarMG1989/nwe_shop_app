import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class CartService {
  static const String _cartKey = 'cart_items';

  // 🛒 Obtener carrito local (sin login)
  static Future<List<Map<String, dynamic>>> getCartLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(_cartKey)) {
        return [];
      }

      final cartJson = prefs.getString(_cartKey);

      if (cartJson == null || cartJson.isEmpty || cartJson == '[]') {
        return [];
      }

      final List<dynamic> cartList = jsonDecode(cartJson);
      return List<Map<String, dynamic>>.from(
        cartList.map((item) {
          if (item is Map) {
            final mapItem = Map<String, dynamic>.from(item);
            if (mapItem.containsKey('precioUnitario')) {
              mapItem['precio'] = mapItem['precioUnitario'];
              mapItem.remove('precioUnitario');
            }

            return mapItem;
          }
          return <String, dynamic>{};
        }),
      );
    } catch (e) {
      print('❌ Error al cargar carrito local: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cartKey);
      } catch (_) {}
      return [];
    }
  }

  // ➕ Agregar producto al carrito local
  static Future<bool> addToCartLocal(Map<String, dynamic> item) async {
    try {
      final cart = await getCartLocal();

      // Verificar si ya existe el producto con la misma talla
      final existingIndex = cart.indexWhere(
        (cartItem) =>
            cartItem['idProducto'] == item['idProducto'] &&
            cartItem['talla'] == item['talla'],
      );

      if (existingIndex != -1) {
        // Si existe, aumentar cantidad
        cart[existingIndex]['cantidad'] =
            ((cart[existingIndex]['cantidad'] ?? 1) as num).toInt() +
            ((item['cantidad'] ?? 1) as num).toInt();
      } else {
        // Si no existe, agregar nuevo
        item['cantidad'] = (item['cantidad'] ?? 1) as num;
        cart.add(item);
      }

      return await _saveCartLocal(cart);
    } catch (e) {
      print('❌ Error al agregar al carrito local: $e');
      return false;
    }
  }

  // ➖ Actualizar cantidad
  static Future<Map<String, dynamic>> updateQuantityLocal(
    int index,
    int cantidad,
    int idProducto,
    int idTalla,
  ) async {
    try {
      final url = "${EnvConfig.baseUrl}/productos/validaInventario";
      final response = await http.get(
        Uri.parse(
          "$url?idProducto=$idProducto&idTalla=$idTalla&cantidad=$cantidad&nocache=${DateTime.now().millisecondsSinceEpoch}",
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final success = responseData is List
            ? responseData.first['success']
            : responseData['success'];

        if (success == 1) {
          final cart = await getCartLocal();
          if (index >= 0 && index < cart.length) {
            cart[index]['cantidad'] = cantidad;
            final saved = await _saveCartLocal(cart);
            return {
              'success': saved,
              'message': saved
                  ? 'Cantidad actualizada correctamente'
                  : 'Error al guardar cambios localmente',
            };
          } else {
            return {'success': false, 'message': 'Índice inválido'};
          }
        } else {
          return {'success': false, 'message': 'Sin inventario disponible'};
        }
      } else {
        return {'success': false, 'message': 'Error en el servidor'};
      }
    } catch (e) {
      print('❌ Error al actualizar cantidad en servidor: $e');
      return {'success': false, 'message': 'Error inesperado'};
    }
  }

  // 🗑️ Eliminar del carrito local
  static Future<bool> removeFromCartLocal(int index) async {
    try {
      final cart = await getCartLocal();
      if (index >= 0 && index < cart.length) {
        cart.removeAt(index);
        return await _saveCartLocal(cart);
      }
      return false;
    } catch (e) {
      print('❌ Error al eliminar del carrito: $e');
      return false;
    }
  }

  // 💾 Guardar carrito
  static Future<bool> _saveCartLocal(List<Map<String, dynamic>> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(cart);
      return await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('❌ Error al guardar carrito: $e');
      return false;
    }
  }

  // 🔄 Sincronizar carrito local con BD (cuando se loguea)
  static Future<bool> syncCartWithServer(int idUsuario) async {
    try {
      final cartLocal = await getCartLocal();

      if (cartLocal.isEmpty) return true;

      // Enviar carrito local al servidor
      final response = await http
          .post(
            Uri.parse("${EnvConfig.baseUrl}/carrito/sincronizar"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idUsuario': idUsuario, 'items': cartLocal}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Limpiar carrito local después de sincronizar
        await clearCartLocal();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error al sincronizar carrito: $e');
      return false;
    }
  }

  // 🧹 Limpiar carrito local
  static Future<bool> clearCartLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_cartKey);
    } catch (e) {
      print('❌ Error al limpiar carrito: $e');
      return false;
    }
  }

  // 📥 Obtener carrito del servidor (con login)
  static Future<List<dynamic>> getCartFromServer(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${EnvConfig.baseUrl}/carrito/getCarrito?idUsuario=$idUsuario&nocache=${DateTime.now().millisecondsSinceEpoch}",
        ),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al cargar carrito del servidor: $e');
      throw Exception('Error al cargar carrito: $e');
    }
  }

  // ➕ Agregar al carrito en servidor
  static Future<bool> addToCartServer(
    int idUsuario,
    Map<String, dynamic> item,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/carrito/postAgregarCarrito"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idProducto': item['idProducto'],
          'idTalla': item['idTalla'],
          'cantidad': item['cantidad'] ?? 1,
          'precioUnitario': item['precioUnitario'],
          'precioOferta': item['precioOferta'],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData[0]['success'] == 1) {
          return true;
        } else {
          return false;
        }
      }

      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // 🗑️ Eliminar del carrito en servidor
  static Future<Map<String, dynamic>> removeFromCartServer(
    int idUsuario,
    int idProducto,
    int idTalla,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse("${EnvConfig.baseUrl}/carrito/deleteEliminarCarrito"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idUsuario': idUsuario,
              'idProducto': idProducto,
              'idTalla': idTalla,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          'success': responseData[0]['success'] == 1,
          'message': responseData[0]['message'] ?? 'Producto eliminado',
        };
      }

      return {'success': false, 'message': 'Error de conexión con el servidor'};
    } catch (e) {
      print('❌ Error al eliminar del carrito en servidor: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ➖ Actualizar cantidad en servidor
  static Future<Map<String, dynamic>> updateQuantityServer(
    int idUsuario,
    int idProducto,
    int idTalla,
    int cantidad,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("${EnvConfig.baseUrl}/carrito/putActualizarCarritoCantidad"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idProducto': idProducto,
          'idTalla': idTalla,
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          'success': responseData[0]['success'] == 1,
          'message': responseData[0]['message'] ?? 'Operación completada',
        };
      }

      return {'success': false, 'message': 'Error de conexión con el servidor'};
    } catch (e) {
      print('❌ Error al actualizar cantidad en servidor: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
