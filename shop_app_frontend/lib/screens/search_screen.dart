import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/text_styles.dart';
import 'package:shop_app/data/data_provider_producto.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/product_screen.dart';
import 'package:shop_app/screens/try_on_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  bool _isSearchExpanded = false;
  Usuario? usuario;
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // ✅ Detectar cuando pierde el foco para contraer
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() {
          _isSearchExpanded = false;
        });
      }
    });
  }

  Future<void> _loadUsuario() async {
    final user = await SeguridadService.getUsuario();

    setState(() {
      usuario = user;
      loadingUser = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openProduct(Map<String, dynamic> producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(producto: producto),
      ),
    );
  }

  // ✅ Función para expandir/contraer el buscador
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      usuario: usuario,
      header: Padding(
        padding: const EdgeInsets.only(
          top: 60.0,
          left: 16.0,
          right: 16.0,
          bottom: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!_isSearchExpanded)
                  Expanded(child: Text("TIENDA", style: TextStyles.saludoText)),

                // Campo de búsqueda animado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isSearchExpanded
                      ? MediaQuery.of(context).size.width - 32
                      : 50,
                  child: _isSearchExpanded
                      ? TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: "Buscar productos...",
                            prefixIcon: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.grey,
                              ),
                              onPressed: _toggleSearch,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.black),
                            onPressed: _toggleSearch,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📌 Tabs de Hombre/Mujer
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: "HOMBRE"),
                  Tab(text: "MUJER"),
                ],
              ),
            ),
          ],
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          ProductoGeneroGrid(
            idGenero: 1,
            searchQuery: _searchQuery,
            onItemTap: _openProduct,
          ),
          ProductoGeneroGrid(
            idGenero: 2,
            searchQuery: _searchQuery,
            onItemTap: _openProduct,
          ),
        ],
      ),
    );
  }
}

// 🛍️ Widget reutilizable para mostrar productos por género
class ProductoGeneroGrid extends StatefulWidget {
  final int idGenero;
  final String searchQuery;
  final Function(Map<String, dynamic>)? onItemTap;

  const ProductoGeneroGrid({
    super.key,
    required this.idGenero,
    required this.searchQuery,
    this.onItemTap,
  });

  @override
  State<ProductoGeneroGrid> createState() => _ProductoGeneroGridState();
}

class _ProductoGeneroGridState extends State<ProductoGeneroGrid> {
  List<dynamic> productos = [];
  bool loading = true;
  List<dynamic> cartItems = [];
  bool isLoggedIn = false;
  int? userId;
  Usuario? usuario;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void didUpdateWidget(ProductoGeneroGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idGenero != widget.idGenero) {
      _loadProductos();
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ProductoService.getProductoGenero(widget.idGenero);
      setState(() {
        productos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<dynamic> get productosFiltrados {
    if (widget.searchQuery.isEmpty) {
      return productos;
    }

    return productos.where((producto) {
      final nombre = (producto["nombre"] ?? "").toString().toLowerCase();
      return nombre.contains(widget.searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Error al cargar productos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductos,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    final productosMostrar = productosFiltrados;

    if (productosMostrar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.searchQuery.isEmpty
                  ? Icons.shopping_bag_outlined
                  : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery.isEmpty
                  ? "No hay productos disponibles"
                  : "No se encontraron productos con '${widget.searchQuery}'",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProductos,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: productosMostrar.length,
        itemBuilder: (context, index) {
          final producto = productosMostrar[index];
          return ProductoCard(producto: producto, onTap: widget.onItemTap);
        },
      ),
    );
  }
}

// 🎴 Tarjeta individual de producto
class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final Function(Map<String, dynamic>)? onTap;

  const ProductoCard({super.key, required this.producto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool tieneOferta = producto["precioOferta"] != null;

    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!(producto);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      producto["fullUrl"] ?? "assets/images/default.jpg",
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto["nombre"] ?? "Sin nombre",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (tieneOferta) ...[
                        Text(
                          "\$${producto["precio"].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          "\$${producto["precioOferta"].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ] else ...[
                        Text(
                          "\$${producto["precio"].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ⭐ BOTÓN TRY-ON (ya funciona)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: "tryon_${producto['id']}",
                mini: true,
                backgroundColor: Colors.black,
                child: const Icon(Icons.auto_awesome, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TryOnScreen(producto: producto),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
