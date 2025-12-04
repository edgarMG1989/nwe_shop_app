import 'package:flutter/material.dart';
import 'package:shop_app/data/data_provider_producto.dart';
import 'package:shop_app/screens/try_on_screen.dart';

class CarouselNovedades extends StatefulWidget {
  final String titulo;
  final String dataKey; // "novedades" o "ofertas"
  final Function(Map<String, dynamic>)? onItemTap;

  const CarouselNovedades({
    super.key,
    required this.titulo,
    required this.dataKey,
    this.onItemTap,
  });

  @override
  State<CarouselNovedades> createState() => _CarouselNovedadesState();
}

class _CarouselNovedadesState extends State<CarouselNovedades> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);

    // ✅ Llamamos al nuevo servicio del backend
    List<dynamic> productos = await ProductoService.getProductosNovedad();

    // Si el carousel es de "ofertas", filtramos
    if (widget.dataKey == "ofertas") {
      productos = productos.where((p) => p["precioOferta"] != null).toList();
    }

    setState(() {
      items = productos;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text("No hay productos disponibles"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            widget.titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final bool tieneOferta = item["precioOferta"] != null;

              return GestureDetector(
                onTap: () {
                  if (widget.onItemTap != null) widget.onItemTap!(item);
                },
                child: Stack(
                  children: [
                    // --- Tarjeta del producto ---
                    Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              item["fullUrl"],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/default.jpg",
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),

                          // Nombre
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Text(
                              item["nombre"],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Precio
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: tieneOferta
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "\$${item["precio"].toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.red,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        "\$${item["precioOferta"].toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "\$${item["precio"]}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // --- Botón TRY ON ---
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton(
                        heroTag:
                            "${widget.dataKey}_carousel_tryon_${item['id']}",
                        mini: true,
                        backgroundColor: Colors.black,
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TryOnScreen(producto: item),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
