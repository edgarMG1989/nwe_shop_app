import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_app/data/data_provider_venta.dart';
import 'package:shop_app/models/usuario_model.dart';
import 'package:shop_app/models/venta_model.dart';
import 'package:shop_app/models/venta_producto_model.dart';
import 'package:shop_app/screens/order_screen.dart';

class OrdersScreen extends StatefulWidget {
  final Usuario? usuario;
  const OrdersScreen({super.key, required this.usuario});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Venta>> _futureVentas;
  Color _getStatusColor(int idEstatus) {
    switch (idEstatus) {
      case 1:
        return Colors.orange; // Registrada
      case 2:
        return Colors.blue; // En preparación
      case 3:
        return Colors.teal; // Enviado
      case 4:
        return Colors.green; // Entregado
      case 5:
        return Colors.red; // Cancelado
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _futureVentas = obtenerVentasUsuario(widget.usuario!.idUsuario);
  }

  String formatearFecha(String fecha) {
    try {
      final parsed = DateTime.parse(fecha);
      return DateFormat("dd MMM yyyy - hh:mm a").format(parsed);
    } catch (e) {
      return fecha;
    }
  }

  Future<List<Venta>> obtenerVentasUsuario(int idUsuario) async {
    final data = await VentaService.getVentaIdUsuario(idUsuario);

    final ventasRaw = data[0];
    final productosRaw = data[1];

    final ventas = ventasRaw.map<Venta>((v) => Venta.fromJson(v)).toList();
    final productos = productosRaw
        .map<VentaProducto>((p) => VentaProducto.fromJson(p))
        .toList();

    for (final v in ventas) {
      v.productos = productos.where((p) => p.idVenta == v.idVenta).toList();
    }

    return ventas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis pedidos"), elevation: 2),
      body: FutureBuilder<List<Venta>>(
        future: _futureVentas,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ventas = snapshot.data!;

          if (ventas.isEmpty) {
            return const Center(
              child: Text(
                "No tienes pedidos aún",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, i) {
              final v = ventas[i];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderScreen(venta: v, usuario: widget.usuario)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ---------------- Mini imágenes de productos ----------------
                      Column(
                        children: v.productos.take(3).map((producto) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(producto.fullUrl),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(width: 16),

                      // ---------------- Información del pedido ----------------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pedido #${v.idVenta}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  formatearFecha(v.fechaCompra),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Estatus
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  v.idEstatusVenta,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                v.estatus,
                                style: TextStyle(
                                  color: _getStatusColor(v.idEstatusVenta),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              "${v.productos.length} productos en este pedido",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Total: \$${v.total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ----------- Flecha centrada -------------
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ],
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
