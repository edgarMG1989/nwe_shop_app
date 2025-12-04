import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env_config.dart';

class FileServerService {
  static Future<Map<String, dynamic>?> uploadImage(XFile file, ruta) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${EnvConfig.fileServerUrl}/files/upload?path=$ruta/"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: file.name,
        ),
      );
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception("Error al subir la imagen: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error FileServer: $e");
      return null;
    }
  }

  static Future<int?> postInsDocumento(Map<String, dynamic> data) async {
    final url = Uri.parse("${EnvConfig.baseUrl}/fileserver/postInsDocumento");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json[0]["idDocumento"];
    }

    return null;
  }
}
