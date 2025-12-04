import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_app/data/data_provider_venta.dart';
import 'package:shop_app/models/venta_model.dart';
import 'package:shop_app/models/usuario_model.dart';

class OrderScreen extends StatefulWidget {
  final Venta venta;
  final Usuario? usuario;

  const OrderScreen({super.key, required this.venta, this.usuario});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late int selectedStatus;
  late String selectedStatusLabel;

  String formatearFecha(String fecha) {
    try {
      final parsed = DateTime.parse(fecha);
      return DateFormat("dd MMM yyyy - hh:mm a").format(parsed);
    } catch (e) {
      return fecha;
    }
  }

  final List<Map<String, dynamic>> estatusOptions = [
    {"id": 1, "label": "Registrada"},
    {"id": 2, "label": "En preparación"},
    {"id": 3, "label": "Enviado"},
    {"id": 4, "label": "Entregado"},
    {"id": 5, "label": "Cancelado"},
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar valores locales
    selectedStatus = widget.venta.idEstatusVenta;
    selectedStatusLabel = widget.venta.estatus;
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.usuario?.idRol == 1;

    return Scaffold(
      appBar: AppBar(title: Text("Pedido #${widget.venta.idVenta}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TIMELINE ----------------
            buildTimeline(),

            const SizedBox(height: 25),

            // ---------------- ADMIN DROPDOWN + BOTÓN ----------------
            if (isAdmin) buildAdminControls(),

            const SizedBox(height: 25),

            // ---------------- INFO DEL PEDIDO ----------------
            _sectionTitle("Información del pedido"),
            _infoCard([
              _rowInfo("Cliente",
                  "${widget.venta.nombre} ${widget.venta.apellido}"),
              _rowInfo("Fecha", formatearFecha(widget.venta.fechaCompra)),
              _rowInfo("Estatus", selectedStatusLabel),
              _rowInfo("Total", "\$${widget.venta.total.toStringAsFixed(2)}"),
            ]),

            const SizedBox(height: 20),

            // ---------------- ENVÍO ----------------
            _sectionTitle("Datos de envío"),
            _infoCard([
              _rowInfo("Dirección", widget.venta.direccion),
              _rowInfo("Teléfono", widget.venta.telefono),
              _rowInfo("Correo", widget.venta.correo),
            ]),

            const SizedBox(height: 20),

            // ---------------- PRODUCTOS ----------------
            _sectionTitle("Productos"),
            const SizedBox(height: 10),
            ...widget.venta.productos.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        p.fullUrl,
                        width: 70,
                        height: 70,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "${p.producto}\nTalla: ${p.talla}  Cant: ${p.cantidad}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Text(
                      "\$${p.precio.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ADMIN CONTROLS ----------------
  Widget buildAdminControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Actualizar estatus",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          value: selectedStatus,
          items: estatusOptions.map((e) {
            return DropdownMenuItem<int>(
              value: e["id"],
              child: Text(e["label"]),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedStatus = value!;
              selectedStatusLabel =
                  estatusOptions.firstWhere((e) => e["id"] == value)["label"];
            });
          },
        ),

        const SizedBox(height: 12),

        // Botón actualizar
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.blue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            await VentaService.actualizarEstatus(
              widget.venta.idVenta,
              selectedStatus,
              widget.usuario!.idUsuario
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Estatus actualizado correctamente"),
              ),
            );
          },
          child: const Text("Actualizar estatus",
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------- TIMELINE ----------------
  Widget buildTimeline() {
    const Color activeColor = Color(0xFF4CAF50);
    const Color inactiveColor = Color(0xFFBDBDBD);

    final pasos = [
      {"id": 1, "label": "Registrada", "icon": Icons.access_time},
      {"id": 2, "label": "En preparación", "icon": Icons.local_shipping_outlined},
      {"id": 3, "label": "Enviado", "icon": Icons.fire_truck_outlined},
      {"id": 4, "label": "Entregado", "icon": Icons.calendar_today_outlined},
    ];

    int currentStep = pasos.indexWhere((p) => p["id"] == selectedStatus);
    if (currentStep == -1) currentStep = 0;

    return SizedBox(
      height: 140,
      child: Row(
        children: List.generate(pasos.length, (index) {
          final active = index <= currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index != 0)
                      Expanded(
                        child: Container(
                          height: 4,
                          color: active ? activeColor : inactiveColor,
                        ),
                      ),
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: active ? activeColor : inactiveColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        pasos[index]["icon"] as IconData,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    if (index != pasos.length - 1)
                      Expanded(
                        child: Container(
                          height: 4,
                          color:
                              (index < currentStep) ? activeColor : inactiveColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  pasos[index]["label"] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.bold : FontWeight.normal,
                    color: active ? activeColor : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
