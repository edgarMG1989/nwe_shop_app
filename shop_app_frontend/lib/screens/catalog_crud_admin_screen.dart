import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/data/data_provider_catalogo.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';

class CatalogoCrudAdminScreen extends StatefulWidget {
  final String catalogo;
  final String titulo;
  final Usuario? usuario;

  const CatalogoCrudAdminScreen({
    super.key,
    required this.catalogo,
    required this.titulo,
    this.usuario,
  });

  @override
  State<CatalogoCrudAdminScreen> createState() =>
      _CatalogoCrudAdminScreenState();
}

class _CatalogoCrudAdminScreenState extends State<CatalogoCrudAdminScreen> {
  bool loading = true;
  Usuario? usuario;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadData();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        filterItems();
      });
    });
  }

  Future<void> loadData() async {
    final user = await SeguridadService.getUsuario();

    try {
      List<dynamic> data;

      if (widget.catalogo == "genero") {
        data = await CatalogoService.getGeneros();
      } else {
        data = await CatalogoService.getTallas();
      }

      items = data.map<Map<String, dynamic>>((item) {
        final map = item as Map<String, dynamic>;

        return {
          "id": map["id"],
          "descripcion": map["genero"] ?? map["talla"], 
          "codigo": map["codigo"],
        };
      }).toList();

      filteredItems = items;
    } catch (e) {
      print("ERROR CARGA CATALOGO: $e");
    }

    setState(() {
      usuario = user;
      loading = false;
    });
  }

  void filterItems() {
    if (_searchQuery.isEmpty) {
      filteredItems = items;
    } else {
      filteredItems = items
          .where(
            (item) => item["descripcion"].toString().toLowerCase().contains(
              _searchQuery,
            ),
          )
          .toList();
    }
  }

  void toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) _searchController.clear();
    });
  }

  Future<void> eliminarItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Deseas eliminar este registro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Llamar servicio de eliminación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Eliminado correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      usuario: usuario,
      header: Padding(
        padding: const EdgeInsets.only(
          top: 60,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            if (!_isSearchExpanded)
              Expanded(
                child: Text(
                  widget.titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 46),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isSearchExpanded
                    ? TextField(
                        key: const ValueKey("search"),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Buscar...",
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: toggleSearch,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: toggleSearch,
                        ),
                      ),
              ),
            ),
            if (!_isSearchExpanded)
              IconButton(
                icon: const Icon(Icons.add_circle, size: 30),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Agregar nuevo (pendiente)")),
                  );
                },
              ),
          ],
        ),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredItems.isEmpty
          ? const Center(child: Text("No hay registros"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              itemBuilder: (_, index) {
                final item = filteredItems[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(item["codigo"])),
                    title: Text(
                      item["descripcion"],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Editar (pendiente)"),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => eliminarItem(item["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
