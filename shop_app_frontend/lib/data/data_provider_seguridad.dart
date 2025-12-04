import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../models/usuario_model.dart';

class SeguridadService {
  static const String _userKey = 'user_data';
  static const String _isLoggedKey = 'is_logged_in';

  // 🔐 Login
  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/seguridad/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuario': correo, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == 1) {
          if (responseData['usuario'] != null) {
            await _saveUserData(responseData['usuario']);
          }

          return {
            'success': true,
            'message': responseData['message'] ?? 'Login exitoso',
            'usuario': responseData['usuario'],
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Usuario o contraseña incorrectos',
          };
        }
      }

      return {'success': false, 'message': 'Error de conexión con el servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 💾 Guardar datos del usuario en local
  static Future<bool> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userData));
      await prefs.setBool(_isLoggedKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 👤 Obtener usuario guardado
  static Future<Usuario?> getUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        return Usuario.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ Verificar si está logueado
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // 🚪 Cerrar sesión
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> createPerfil(
    String nombre,
    String apellidoPaterno,
    String telefono,
    String correo,
    String password, {
    int? idDocumento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/seguridad/postInsPerfil"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellidoPaterno': apellidoPaterno,
          'telefono': telefono,
          'correo': correo,
          'password': password,
          "idDocumento": idDocumento,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final spResult = responseData[0][0];
        final usuarioData = responseData[1][0];

        if (spResult['success'] == 1) {
          await _saveUserData(usuarioData);

          return {
            'success': true,
            'message': spResult['message'] ?? 'Perfil creado',
            'usuario': usuarioData,
          };
        } else {
          return {
            'success': false,
            'message': spResult['message'] ?? 'Error desconocido',
          };
        }
      }

      return {'success': false, 'message': 'Error de conexión con el servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePerfil(
    String nombre,
    String apellidoPaterno,
    String telefono,
    String correo,
    String password, {
    int? idDocumento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/seguridad/updatePerfil"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellidoPaterno': apellidoPaterno,
          'telefono': telefono,
          'correo': correo,
          'password': password,
          "idDocumento": idDocumento,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final spResult = responseData[0][0];
        final usuarioData = responseData[1][0];

        if (spResult['success'] == 1) {
          await _saveUserData(usuarioData);

          return {
            'success': true,
            'message': spResult['message'] ?? 'Perfil actualizado',
            'usuario': usuarioData,
          };
        } else {
          return {
            'success': false,
            'message': spResult['message'] ?? 'Error desconocido',
          };
        }
      }

      return {'success': false, 'message': 'Error de conexión con el servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
