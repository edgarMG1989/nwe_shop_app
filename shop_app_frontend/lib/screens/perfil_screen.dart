import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/input_styles.dart';
import 'package:shop_app/core/button_styles.dart';
import 'package:shop_app/core/text_styles.dart';
import 'package:shop_app/data/data_provider_fileserver.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/home_screen.dart';
import 'package:shop_app/screens/login_screen.dart';
import 'package:shop_app/screens/orders_screen.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario? usuario;

  const PerfilScreen({super.key, this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _obscurePassword = true;
  Usuario? usuario;
  bool _isLoading = false;
  XFile? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
  bool _subiendoImagen = false;
  int? _idDocumento;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    final user = await SeguridadService.getUsuario();
    setState(() {
      usuario = user;
      _nombreController.text = user!.nombre;
      _apellidoController.text = user.apellidoPaterno;
      _telefonoController.text = user.telefono!;
      _correoController.text = user.correo;
    });
  }

  Future<void> _updatePerfil() async {
    setState(() => _isLoading = true);

    try {
      final result = await SeguridadService.updatePerfil(
        _nombreController.text.trim(),
        _apellidoController.text.trim(),
        _telefonoController.text.trim(),
        _correoController.text.trim(),
        _passwordController.text,
        idDocumento: _idDocumento,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
      });
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

    final bodyDoc = {
      "filename": data["filename"],
      "originalName": data["originalName"],
      "path": data["path"],
      "url": data["url"],
      "fullUrl": data["fullUrl"],
      "localPath": data["localPath"],
      "size": data["size"],
    };

    final idDoc = await FileServerService.postInsDocumento(bodyDoc);

    if (idDoc != null) {
      setState(() {
        _idDocumento = idDoc;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Imagen subida")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Error guardando documento")),
      );
    }
  }

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3,
      usuario: usuario,
      header: Padding(
        padding: const EdgeInsets.only(
          top: 60.0,
          left: 16.0,
          right: 16.0,
          bottom: 20.0,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "HOLA, ${usuario?.nombre.toUpperCase() ?? ''}",
            style: TextStyles.saludoText,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imagenSeleccionada != null
                          ? FileImage(File(_imagenSeleccionada!.path))
                          : (usuario?.fullUrl != null
                                    ? NetworkImage(usuario!.fullUrl!)
                                    : null)
                                as ImageProvider?,
                      child:
                          _imagenSeleccionada == null &&
                              usuario?.fullUrl == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_imagenSeleccionada != null)
                    ElevatedButton.icon(
                      icon: _subiendoImagen
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.cloud_upload),
                      label: const Text("Subir imagen"),
                      onPressed: _subiendoImagen ? null : _subirImagen,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            Text(
              "Tu perfil",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            // 🔹 Acceso rápido: Mis pedidos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.shopping_bag,
                  size: 30,
                  color: Color(0xFF248FAA),
                ),
                title: const Text(
                  "Mis pedidos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdersScreen(usuario: usuario),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // 🔹 Campos del formulario
            TextFormField(
              controller: _nombreController,
              decoration: InputStyles.textField("Nombre", Icons.account_circle),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              decoration: InputStyles.textField(
                "Apellido paterno",
                Icons.badge,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: InputStyles.textField("Teléfono", Icons.phone),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputStyles.textField(
                "Correo electrónico",
                Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration:
                  InputStyles.textField(
                    "Contraseña",
                    Icons.lock_outlined,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 30),

            // 🔹 Botón Editar Perfil
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updatePerfil,
              icon: const Icon(Icons.edit),
              label: const Text("Editar perfil"),
              style: ButtonStyles.primaryButton,
            ),

            const SizedBox(height: 15),

            // 🔹 Botón Cerrar Sesión
            ElevatedButton.icon(
              onPressed: () async {
                final success = await SeguridadService.logout();
                if (success) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ButtonStyles.redButton,
            ),
          ],
        ),
      ),
    );
  }
}
