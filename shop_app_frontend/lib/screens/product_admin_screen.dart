import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/data/data_provider_producto.dart';
import 'package:shop_app/screens/product_edit_admin_screen.dart';
import 'package:shop_app/screens/product_new_admin_screen.dart';

class ProductAdminScreen extends StatefulWidget {
  final Usuario? usuario;

  const ProductAdminScreen({super.key, this.usuario});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  Usuario? usuario;
  bool loading = true;

  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];

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
        _filtrarProductos();
      });
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _isSearchExpanded = false);
      }
    });
  }

  void _filtrarProductos() {
    if (_searchQuery.isEmpty) {
      productosFiltrados = productos;
    } else {
      productosFiltrados = productos.where((p) {
        final nombre = p["nombre"]?.toString().toLowerCase() ?? "";
        return nombre.contains(_searchQuery);
      }).toList();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _openProduct(Map<String, dynamic> producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductEditAdminScreen(idProducto: producto['idProducto']),
      ),
    );
  }

  Future<void> loadData() async {
    final user = await SeguridadService.getUsuario();
    final lista = await ProductoService.getProductoAll();

    setState(() {
      usuario = user;
      productos = lista;
      productosFiltrados = lista;
      loading = false;
    });
  }

  Future<void> eliminarProducto(int idProducto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Seguro que deseas eliminar este producto?"),
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

    if (confirm != true) return;

    final result = await ProductoService.deleteProducto(idProducto);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == 1 ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    if (result['success'] == 1) {
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainLayout(
      currentIndex: 0,
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
            if (!_isSearchExpanded)
              Expanded(
                child: Text(
                  "Gestión de Productos",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isSearchExpanded
                    ? TextField(
                        key: const ValueKey("search"),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Buscar productos...",
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _toggleSearch,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
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
                          onPressed: _toggleSearch,
                        ),
                      ),
              ),
            ),
            if (!_isSearchExpanded)
              IconButton(
                icon: const Icon(Icons.add_circle, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductNewAdminScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      child: productosFiltrados.isEmpty
          ? const Center(child: Text("No hay productos registrados"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: productosFiltrados.length,
              itemBuilder: (_, index) {
                final p = productosFiltrados[index];

                final tieneOferta = p["precioOferta"] != null;
                final precio = (p["precio"] as num?) ?? 0;
                final precioOferta = (p["precioOferta"] as num?) ?? 0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: p["fullUrl"] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p["fullUrl"],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/images/default.jpg",
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            )
                          : const Icon(Icons.image_not_supported),
                    ),
                    title: Text(
                      "${p["nombre"]}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tieneOferta) ...[
                          Text(
                            "\$${precio.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            "\$${precioOferta.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ] else ...[
                          Text(
                            "\$${precio.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _openProduct(p);
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => eliminarProducto(p["idProducto"]),
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
