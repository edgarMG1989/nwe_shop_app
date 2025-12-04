import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_app/core/input_styles.dart';
import 'package:shop_app/core/button_styles.dart';
import 'package:shop_app/data/data_provider_fileserver.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/home_screen.dart';
import 'package:shop_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imagenSeleccionada;
  bool _subiendoImagen = false;
  int? _idDocumento;

  Future<void> _seleccionarImagen() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _imagenSeleccionada = img);
    }
  }

  Future<void> _subirImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _subiendoImagen = true);

    final resp = await FileServerService.uploadImage(
      _imagenSeleccionada!,
      'USUARIO',
    );

    setState(() => _subiendoImagen = false);

    if (resp == null || resp["data"] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Error al subir imagen")));
      return;
    }

    final data = resp["data"];

    final idDoc = await FileServerService.postInsDocumento({
      "filename": data["filename"],
      "originalName": data["originalName"],
      "path": data["path"],
      "url": data["url"],
      "fullUrl": data["fullUrl"],
      "localPath": data["localPath"],
      "size": data["size"],
    });

    if (idDoc != null) {
      setState(() => _idDocumento = idDoc);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Imagen subida")));
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resp = await SeguridadService.createPerfil(
      _nombreController.text.trim(),
      _apellidoController.text.trim(),
      _telefonoController.text.trim(),
      _correoController.text.trim(),
      _passwordController.text.trim(),
      idDocumento: _idDocumento,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resp["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Bienvenido',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      final loginResp = await SeguridadService.login(
        _correoController.text.trim(),
        _passwordController.text.trim(),
      );

      if (loginResp["success"]) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(usuario: Usuario.fromJson(loginResp["usuario"])),
          ),
          (r) => false,
        );
      }

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resp["message"]), backgroundColor: Colors.red),
    );
  }

  bool get formularioCompleto {
    return _nombreController.text.trim().isNotEmpty &&
        _apellidoController.text.trim().isNotEmpty &&
        _telefonoController.text.trim().isNotEmpty &&
        _correoController.text.trim().isNotEmpty &&
        _passwordController.text.trim().length >= 4 &&
        _imagenSeleccionada != null &&
        _idDocumento != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Regístrate")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // FOTO
              GestureDetector(
                onTap: _seleccionarImagen,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _imagenSeleccionada != null
                      ? FileImage(File(_imagenSeleccionada!.path))
                      : null,
                  child: _imagenSeleccionada == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              if (_imagenSeleccionada != null)
                ElevatedButton.icon(
                  onPressed: _subiendoImagen ? null : _subirImagen,
                  icon: _subiendoImagen
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.cloud_upload),
                  label: const Text("Subir imagen"),
                ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _nombreController,
                decoration: InputStyles.textField("Nombre", Icons.person),
                validator: (v) => v!.isEmpty ? "Ingresa el nombre" : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _apellidoController,
                onChanged: (_) => setState(() {}),
                decoration: InputStyles.textField(
                  "Apellido paterno",
                  Icons.badge,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputStyles.textField("Teléfono", Icons.phone),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputStyles.textField(
                  "Correo electrónico",
                  Icons.email,
                ),
                validator: (v) => v!.isEmpty ? "Ingresa tu correo" : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputStyles.textField("Contraseña", Icons.lock)
                    .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                validator: (v) => v!.length < 4
                    ? "La contraseña debe tener mínimo 4 caracteres"
                    : null,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: (!_isLoading && formularioCompleto)
                    ? _registrar
                    : null,
                style: ButtonStyles.primaryButton,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Crear cuenta"),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
