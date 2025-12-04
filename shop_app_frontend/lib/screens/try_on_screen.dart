import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_app/data/data_provider_producto.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TryOnScreen extends StatefulWidget {
  final Map<String, dynamic> producto;

  const TryOnScreen({super.key, required this.producto});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  File? userImage;
  bool processing = false;
  String? resultImageUrl;
  String? errorMessage;

  Future<void> pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Selecciona una opción",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text("Tomar foto"),
                  subtitle: const Text("Usa la cámara"),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final picked = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setState(() {
                          userImage = File(picked.path);
                          resultImageUrl = null;
                          errorMessage = null;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No hay cámara disponible."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text("Elegir de galería"),
                  subtitle: const Text("Selecciona una foto"),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setState(() {
                        userImage = File(picked.path);
                        resultImageUrl = null;
                        errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> generarTryOn() async {
    if (userImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, sube primero una foto tuya"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      processing = true;
      errorMessage = null;
    });

    try {
      final garmentFile = await urlToFile(widget.producto["fullUrl"]);
      final result = await ProductoService.generate(
        userImage!,
        garmentFile,
        widget.producto["valor"],
      );

      if (mounted) {
        setState(() {
          processing = false;
          if (result != null) {
            resultImageUrl = result;
          } else {
            errorMessage = "No se pudo generar la imagen. Intenta de nuevo.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          processing = false;
          errorMessage = "Error: ${e.toString()}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<File> urlToFile(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception("Error al descargar la imagen de la prenda");
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/tempGarment_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  // Función para mostrar imagen en pantalla completa
  void showFullImage(BuildContext context, String base64Image) {
    final base64String = base64Image.contains(",")
        ? base64Image.split(",")[1]
        : base64Image;
    final bytes = base64Decode(base64String);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Resultado Virtual Try-On",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Aquí podrías implementar guardar la imagen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Función de descarga próximamente"),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildResultImage() {
    if (resultImageUrl == null) return const SizedBox.shrink();

    try {
      final base64String = resultImageUrl!.contains(",")
          ? resultImageUrl!.split(",")[1]
          : resultImageUrl!;

      final bytes = base64Decode(base64String);

      return GestureDetector(
        onTap: () => showFullImage(context, resultImageUrl!),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  bytes,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Toca para ampliar",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 10),
              const Text(
                "Error al cargar la imagen generada",
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 5),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Probador Virtual IA"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prenda seleccionada
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.producto["fullUrl"],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.producto["nombre"] ?? "Prenda",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Prenda seleccionada para probar",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Instrucciones
            if (userImage == null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Sube una foto de cuerpo completo para mejores resultados",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Imagen del usuario
            if (userImage == null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Sube una foto tuya",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    userImage!,
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Botones
            ElevatedButton.icon(
              onPressed: processing ? null : pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(userImage == null ? "Subir foto" : "Cambiar foto"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: (processing || userImage == null)
                  ? null
                  : generarTryOn,
              icon: processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.checkroom),
              label: Text(processing ? "Generando..." : "🪄 Probar prenda"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (processing) ...[
              const SizedBox(height: 30),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 15),
                    Text(
                      "🎨 Generando tu look virtual...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Esto puede tardar 30-60 segundos",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            if (resultImageUrl != null) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    "¡Resultado!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                "Así te verías con esta prenda",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              buildResultImage(),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    resultImageUrl = null;
                    userImage = null;
                  });
                },
                icon: const Icon(Icons.replay),
                label: const Text("Probar de nuevo"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
