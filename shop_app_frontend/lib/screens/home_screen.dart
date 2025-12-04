import 'package:flutter/material.dart';
import 'package:shop_app/components/carousel_novedades.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/text_styles.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/screens/product_admin_screen.dart';
import 'package:shop_app/screens/product_screen.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final Usuario? usuario;
  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Usuario? usuario;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    if (widget.usuario != null) {
      setState(() {
        usuario = widget.usuario;
        loading = false;
      });
    } else {
      final user = await SeguridadService.getUsuario();
      setState(() {
        usuario = user;
        loading = false;
      });
    }
  }

  void _openProduct(Map<String, dynamic> producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(producto: producto),
      ),
    );
  }

  Future<void> _abrirEnlace(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usuario?.idRol == 1) {
      return ProductAdminScreen(usuario: usuario);
    }

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainLayout(
      currentIndex: 0,
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
            usuario != null
                ? "HOLA, ${usuario!.primerNombre.toUpperCase()}"
                : "HOLA, INVITADO",
            style: TextStyles.saludoText,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselNovedades(
              titulo: "Novedades",
              dataKey: "novedades",
              onItemTap: _openProduct,
            ),
            const SizedBox(height: 20),
            CarouselNovedades(
              titulo: "Ofertas",
              dataKey: "ofertas",
              onItemTap: _openProduct,
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text(
                    "CONTÁCTANOS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.facebook,
                          color: Colors.blue,
                          size: 36,
                        ),
                        onPressed: () => _abrirEnlace(
                          "https://www.facebook.com/search/top?q=la%20ropa%20nostra&locale=es_LA",
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.purple,
                          size: 36,
                        ),
                        onPressed: () => _abrirEnlace(
                          "https://www.instagram.com/laropa.nostraa/",
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Image.asset(
                          "assets/images/whatsappIcon.webp",
                          height: 55,
                          width: 55,
                        ),
                        onPressed: () => _abrirEnlace(
                          "https://wa.me/525549192247?text=Hola!%20Quisiera%20más%20información",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
