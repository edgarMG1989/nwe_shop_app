import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/text_styles.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/catalog_crud_admin_screen.dart';

class CatalogsAdminScreen extends StatefulWidget {
  final Usuario? usuario;
  const CatalogsAdminScreen({super.key, this.usuario});

  @override
  State<CatalogsAdminScreen> createState() => _CatalogsAdminScreenState();
}

class _CatalogsAdminScreenState extends State<CatalogsAdminScreen> {
  Usuario? usuario;
  bool loading = true;

  final List<Map<String, dynamic>> catalogos = [
    {"nombre": "Géneros", "icono": Icons.male, "clave": "genero"},
    {"nombre": "Tallas", "icono": Icons.straighten, "clave": "talla"},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final user = await SeguridadService.getUsuario();
    setState(() {
      usuario = user;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      usuario: usuario,
      header: Padding(
        padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
        child: Text("CATÁLOGOS", style: TextStyles.saludoText),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: .9,
        ),
        itemCount: catalogos.length,
        itemBuilder: (context, index) {
          final item = catalogos[index];
          return CatalogoCard(
            icono: item["icono"],
            titulo: item["nombre"],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => CatalogoCrudAdminScreen(
                    catalogo: item["clave"],
                    titulo: item["nombre"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CatalogoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  const CatalogoCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(titulo, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
