import 'package:flutter/material.dart';
import 'package:shop_app/components/main_layout.dart';
import 'package:shop_app/core/text_styles.dart';
import 'package:shop_app/data/data_provider_cart.dart';
import 'package:shop_app/data/data_provider_seguridad.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool loading = true;
  bool isLoggedIn = false;
  int? userId;
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUsuario();
    await _loadCart();
  }

  Future<void> _loadUsuario() async {
    final logged = await SeguridadService.isLoggedIn();
    final user = await SeguridadService.getUsuario();

    setState(() {
      isLoggedIn = logged;
      userId = user?.idUsuario;
      usuario = user;
    });
  }

  Future<void> _loadCart() async {
    setState(() => loading = true);

    try {
      if (isLoggedIn && userId != null) {
        // Cargar desde el servidor
        final data = await CartService.getCartFromServer(userId!);
        setState(() {
          cartItems = data;
          loading = false;
        });
      } else {
        // Cargar desde almacenamiento local
        final data = await CartService.getCartLocal();
        setState(() {
          cartItems = data;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        cartItems = [];
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar carrito. Se inicializó uno nuevo.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final item = cartItems[index];

    try {
      if (isLoggedIn && userId != null) {
        // ✅ Ahora recibe un Map con success y message
        final result = await CartService.removeFromCartServer(
          userId!,
          item['idProducto'],
          item['idTalla'],
        );

        if (result['success']) {
          // ✅ Éxito - recargar carrito
          await _loadCart();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // ❌ Error - mostrar mensaje del servidor
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Local storage
        await CartService.removeFromCartLocal(index);
        await _loadCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto eliminado del carrito')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return;

    final item = cartItems[index];

    try {
      if (isLoggedIn && userId != null) {
        final result = await CartService.updateQuantityServer(
          userId!,
          item['idProducto'],
          item['idTalla'],
          newQuantity,
        );

        if (result['success']) {
          await _loadCart();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Local storage
        final result = await CartService.updateQuantityLocal(
          index,
          newQuantity,
          item['idProducto'],
          item['idTalla'],
        );
        if (result['success']) {
          await _loadCart();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _calcularTotal() {
    return cartItems.fold(0.0, (total, item) {
      final precio = item['precioOferta'] ?? item['precio'] ?? 0.0;
      final cantidad = item['cantidad'] ?? 1;
      return total + (precio * cantidad);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
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
          child: Text("CARRITO", style: TextStyles.saludoText),
        ),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemCard(
                        item: item,
                        index: index,
                        onRemove: () => _removeItem(index),
                        onQuantityChanged: (newQuantity) =>
                            _updateQuantity(index, newQuantity),
                      );
                    },
                  ),
                ),
                _buildTotalBar(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Tu carrito está vacío",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Agrega productos para comenzar",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBar() {
    final total = _calcularTotal();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  "\$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      cartItems: cartItems,
                      total: total,
                      usuario: usuario,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "COMPRAR",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cantidad = item['cantidad'] ?? 1;
    final precio = item['precioOferta'] ?? item['precio'] ?? 0.0;
    final tieneOferta = item['precioOferta'] != null;

    return Dismissible(
      key: Key('${item['idProducto']}_${item['talla']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 📸 Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item['fullUrl'] ?? 'assets/images/default.jpg',
                width: 80,
                height: 80,
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
            const SizedBox(width: 12),

            // 📝 Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nombre'] ?? 'Producto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Talla: ${item['codigoTalla'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  // 💲 Precio
                  if (tieneOferta) ...[
                    Text(
                      "\$${item['precio']}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      "\$${precio.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "\$${precio.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 🔢 Controles de cantidad
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => onQuantityChanged(cantidad + 1),
                ),
                Text(
                  "$cantidad",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle,
                    color: cantidad > 1 ? Colors.red : Colors.grey,
                  ),
                  onPressed: cantidad > 1
                      ? () => onQuantityChanged(cantidad - 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
