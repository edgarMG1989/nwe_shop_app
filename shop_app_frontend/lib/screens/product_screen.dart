import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/data/data_provider_cart.dart';
import 'package:shop_app/data/data_provider_producto.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/screens/cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final Map<String, dynamic> producto;

  const ProductScreen({super.key, required this.producto});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<dynamic> inventario = [];
  Map<String, dynamic>? tallaSeleccionada;
  int? cantidadSeleccionada;
  bool cargando = true;
  bool agregandoCarrito = false;

  bool isLoggedIn = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _cargarInventario();
  }

  Future<void> _loadUsuario() async {
    final logged = await SeguridadService.isLoggedIn();
    final usuario = await SeguridadService.getUsuario();

    setState(() {
      isLoggedIn = logged;
      userId = usuario?.idUsuario;
    });
  }

  Future<void> _cargarInventario() async {
    try {
      final data = await ProductoService.getProductoInventario(
        widget.producto["id"],
      );
      setState(() {
        inventario = data;
        cargando = false;
      });
    } catch (e) {
      print("❌ Error al cargar inventario: $e");
      setState(() => cargando = false);
    }
  }

  // ✅ Función para agregar al carrito
  Future<void> _agregarAlCarrito() async {
    if (tallaSeleccionada == null || cantidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor selecciona talla y cantidad"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => agregandoCarrito = true);

    try {
      final item = {
        'idProducto': widget.producto["id"],
        'precioUnitario': widget.producto["precio"],
        'precioOferta': widget.producto["precioOferta"],
        'idTalla': tallaSeleccionada!["id"],
        'cantidad': cantidadSeleccionada!,
        'nombre': widget.producto["nombre"],
        'descripcion': widget.producto["descripcion"],
        'codigoTalla': tallaSeleccionada!["codigo"],
        'fullUrl': widget.producto["fullUrl"],
      };

      bool success = false;

      if (isLoggedIn && userId != null) {
        // Agregar al carrito en el servidor
        success = await CartService.addToCartServer(userId!, item);
      } else {
        // Agregar al carrito local
        success = await CartService.addToCartLocal(item);
      }

      setState(() => agregandoCarrito = false);

      if (success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "¡Producto agregado!",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${widget.producto["nombre"]} - Talla ${tallaSeleccionada!["codigo"]}",
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: "VER CARRITO",
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const CartScreen(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ),
          );

          // Resetear selección
          setState(() {
            tallaSeleccionada = null;
            cantidadSeleccionada = null;
          });
        }
      } else {
        throw Exception("No se pudo agregar al carrito");
      }
    } catch (e) {
      setState(() => agregandoCarrito = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final bool tieneOferta = producto["precioOferta"] != null;
    final disponibles = inventario
        .where((item) => item["cantidad"] > 0)
        .toList();

    return MainLayout(
      currentIndex: 0,
      header: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          producto["nombre"],
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                producto["fullUrl"],
                height: 250,
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
            const SizedBox(height: 16),

            // 💲 Precios
            tieneOferta
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\$${producto["precio"]}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        "\$${producto["precioOferta"]}",
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "\$${producto["precio"]}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

            const SizedBox(height: 24),

            // 👕 Tallas
            const Text(
              "Tallas disponibles:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (cargando)
              const Center(child: CircularProgressIndicator())
            else if (inventario.isEmpty || disponibles.isEmpty)
              const Text(
                "Sin disponibilidad",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Wrap(
                spacing: 10,
                children: inventario.map((item) {
                  final bool disponible = item["cantidad"] > 0;
                  final bool seleccionada = tallaSeleccionada == item;

                  return ChoiceChip(
                    label: Text(item["codigo"]),
                    selected: seleccionada,
                    onSelected: disponible
                        ? (value) {
                            setState(() {
                              tallaSeleccionada = value ? item : null;
                              cantidadSeleccionada = null;
                            });
                          }
                        : null,
                    selectedColor: Colors.green.shade300,
                    disabledColor: Colors.grey.shade300,
                    labelStyle: TextStyle(
                      color: disponible ? Colors.black : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // 🔽 Cantidad
            if (tallaSeleccionada != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cantidad:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    hint: const Text("Selecciona cantidad"),
                    value: cantidadSeleccionada,
                    isExpanded: true,
                    items: List.generate(
                      tallaSeleccionada!["cantidad"],
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text("${index + 1}"),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => cantidadSeleccionada = value);
                    },
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // 🛒 Botón Agregar al carrito
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: agregandoCarrito
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.shopping_cart_outlined, size: 24),
                label: Text(
                  agregandoCarrito ? "Agregando..." : "Agregar al carrito",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF248FAA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                onPressed:
                    (tallaSeleccionada != null &&
                        cantidadSeleccionada != null &&
                        !agregandoCarrito)
                    ? _agregarAlCarrito
                    : null,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
